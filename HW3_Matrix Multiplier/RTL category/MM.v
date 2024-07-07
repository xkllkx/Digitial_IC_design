`timescale 1ns/10ps

// 
// Designer: M16121093
//

module MM
#(parameter DATA_WIDTH=8 )(
input wire [DATA_WIDTH-1:0] in_data , 
input wire                  col_end, 
input wire                  row_end, 
output reg                  is_legal, 
output wire [19:0]          out_data,
input wire                  rst, 
input wire                  clk , 
output reg                  change_row,
output wire                 valid,
output reg                  busy                 );

// ------------------------
// Parameters
// ------------------------

//* 1. for loop int
integer i , j ;
//* 2. fontrol flags
reg output_is_done_flag ;
reg current_input_is_A_or_B ; //! 0:A 1:B
reg input_is_done_flag ;
//* 3. counter
reg [1:0] saving_cnt_i , saving_cnt_j ;
reg [1:0] cal_cnt_i , cal_cnt_j ;
//* 4. storage
//! Matrix A (n,m) x Matrix B (m,p) = Matrix C (n,p)
reg [1:0] A_m ;
reg [1:0] A_n ;
reg [1:0] B_m ;
reg [1:0] B_p ;
reg [DATA_WIDTH-1:0] matrix_A [0:3] [0:3] ;
reg [DATA_WIDTH-1:0] matrix_B [0:3] [0:3] ;
//* IP 
//! These are the input ports of the mult adder 
//! A1, A2, A3, B1, B2, B3 would be synthesized into wires
reg [DATA_WIDTH-1:0] A1 ;
reg [DATA_WIDTH-1:0] A2 ;
reg [DATA_WIDTH-1:0] A3 ;
reg [DATA_WIDTH-1:0] A4 ;
reg [DATA_WIDTH-1:0] B1 ;
reg [DATA_WIDTH-1:0] B2 ;
reg [DATA_WIDTH-1:0] B3 ;
reg [DATA_WIDTH-1:0] B4 ;
wire [DATA_WIDTH*2+3:0] IP_out_data ;
//* Pipeline registers
reg input_is_done_flag_q ;
reg output_is_done_flag_q ;
reg valid_q ;
reg change_row_q ;

wire input_end_assert;

// ------------------------
// Output 
// ------------------------
//* valid
assign valid = valid_q | ~is_legal ;

//* busy
always @(posedge clk or posedge rst) begin
    if (rst)                                  busy <= 0 ;        
    else if (input_end_assert)                busy <= 1 ;
    else if (output_is_done_flag | ~is_legal) busy <= 0 ;
end

//* out_data
assign out_data = IP_out_data ;

//* change_row
always @(posedge clk) change_row_q <= cal_cnt_i == B_p ;
always @(posedge clk) change_row <= change_row_q ;

//* is_legal
always @(posedge clk or posedge rst) begin
    if (rst)                     is_legal <= 1 ;
    else if (is_legal==0)        is_legal <= 1 ;
    else if (input_is_done_flag) is_legal <= (A_m == B_m);
end

// ------------------------
// Data storage 
// ------------------------

//* current_input_is_A_or_B
always @(posedge clk or posedge rst) begin
    if (rst) current_input_is_A_or_B <= 0 ;
    else if (row_end) current_input_is_A_or_B <= ~current_input_is_A_or_B ;
end

//* A_m , A_n , B_m , B_p 
//! Reset function can't be removed here.
always @(posedge clk or posedge rst) begin
    if (rst) begin
        A_m <= 0 ;
        A_n <= 0 ;
        B_m <= 0 ;
        B_p <= 0 ;
    end else begin
        if (~busy) begin
            if (~current_input_is_A_or_B) begin         // A input
                if (col_end & ~row_end) A_m <= 0 ;
                else A_m <= A_m + 1;

                A_n <= A_n + col_end ;
            end else begin                              // B input
                if (col_end & ~row_end) B_p <= 0 ;
                else B_p <= B_p + 1;

                B_m <= B_m + col_end ;
            end
        end else if (output_is_done_flag | ~is_legal) begin
            A_m <= 0 ;
            A_n <= 0 ;
            B_m <= 0 ;
            B_p <= 0 ;
        end
    end
end

//* saving cnt 
always @(posedge clk or posedge rst) begin
    if (rst) begin
        saving_cnt_i <= 0;
        saving_cnt_j <= 0;
    end else begin
        if (~busy) begin
            if (row_end) begin
                saving_cnt_i <= 0 ;
                saving_cnt_j <= 0 ;
            end else if (col_end) begin  
                saving_cnt_i <= 0 ;
                saving_cnt_j <= saving_cnt_j + 1 ;
            end else begin
                saving_cnt_i <= saving_cnt_i + 1 ;
                saving_cnt_j <= saving_cnt_j ;
            end
        end else begin
            saving_cnt_i <= 0;
            saving_cnt_j <= 0;
        end
    end
end

// * Matrix A (n,m) , Matrix B (m,p) 
// TODO : try to remove the reset function
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i=0;i<4;i=i+1) begin
            for (j=0;j<4;j=j+1) begin
                matrix_A[i][j] <= 0;
                matrix_B[i][j] <= 0;
            end
        end
    end else if (~busy) begin
        if (~current_input_is_A_or_B) begin
            matrix_A[saving_cnt_j][saving_cnt_i] <= in_data ;
        end else begin
            matrix_B[saving_cnt_j][saving_cnt_i] <= in_data ;
        end
    end else if (output_is_done_flag | ~is_legal) begin
        for (i=0;i<4;i=i+1) begin
            for (j=0;j<4;j=j+1) begin
                matrix_A[i][j] <= 0;
                matrix_B[i][j] <= 0;
            end
        end
    end
end

// ------------------------
// Calculate 
// ------------------------

//* input_is_done_flag_q
assign input_end_assert = row_end & current_input_is_A_or_B ;
always @(posedge clk) input_is_done_flag <= input_end_assert ;
always @(posedge clk) input_is_done_flag_q <= input_is_done_flag ;

//* cal_cnt
always @(posedge clk) begin
    if (~busy) begin 
        cal_cnt_i <= 1;
        cal_cnt_j <= 1;
    end else if (busy) begin
        if (cal_cnt_i == B_p &&cal_cnt_j == A_n) begin
            cal_cnt_i <= 1;
            cal_cnt_j <= 1;
        end else if (cal_cnt_i == B_p) begin
            cal_cnt_i <= 1;
            cal_cnt_j <= cal_cnt_j + 1;
        end else begin
            cal_cnt_i <= cal_cnt_i + 1;
            cal_cnt_j <= cal_cnt_j ;
        end
    end
end

//* IP input
always @(*) begin
    A1 = matrix_A[cal_cnt_j-1][0];
    A2 = matrix_A[cal_cnt_j-1][1];
    A3 = matrix_A[cal_cnt_j-1][2];
    A4 = matrix_A[cal_cnt_j-1][3];
    B1 = matrix_B[0][cal_cnt_i-1];
    B2 = matrix_B[1][cal_cnt_i-1];
    B3 = matrix_B[2][cal_cnt_i-1];
    B4 = matrix_B[3][cal_cnt_i-1];
end

//* valid_q
always @(posedge clk or posedge rst) begin
    if (rst)                            valid_q <= 0 ;
    else begin
        if      (~is_legal)             valid_q <= 0 ;
        else if (input_is_done_flag_q)  valid_q <= 1 ;
        else if (output_is_done_flag )  valid_q <= 0 ;
    end
end

//* output_is_done_flag
wire output_is_done_assert = busy && (cal_cnt_i == B_p && cal_cnt_j == A_n) ;
always @(posedge clk) output_is_done_flag_q <= output_is_done_assert ;
always @(posedge clk) output_is_done_flag <= output_is_done_flag_q ;

//* Only for testing ( vcd can't dump 2-D array)
// wire [DATA_WIDTH-1:0] A_0_0 = matrix_A[0][0];
// wire [DATA_WIDTH-1:0] A_0_1 = matrix_A[0][1];
// wire [DATA_WIDTH-1:0] A_0_2 = matrix_A[0][2];
// wire [DATA_WIDTH-1:0] A_1_0 = matrix_A[1][0];
// wire [DATA_WIDTH-1:0] A_1_1 = matrix_A[1][1];
// wire [DATA_WIDTH-1:0] A_1_2 = matrix_A[1][2];
// wire [DATA_WIDTH-1:0] A_2_0 = matrix_A[2][0];
// wire [DATA_WIDTH-1:0] A_2_1 = matrix_A[2][1];
// wire [DATA_WIDTH-1:0] A_2_2 = matrix_A[2][2];
// wire [DATA_WIDTH-1:0] B_0_0 = matrix_B[0][0];
// wire [DATA_WIDTH-1:0] B_0_1 = matrix_B[0][1];
// wire [DATA_WIDTH-1:0] B_0_2 = matrix_B[0][2];
// wire [DATA_WIDTH-1:0] B_1_0 = matrix_B[1][0];
// wire [DATA_WIDTH-1:0] B_1_1 = matrix_B[1][1];
// wire [DATA_WIDTH-1:0] B_1_2 = matrix_B[1][2];
// wire [DATA_WIDTH-1:0] B_2_0 = matrix_B[2][0];
// wire [DATA_WIDTH-1:0] B_2_1 = matrix_B[2][1];
// wire [DATA_WIDTH-1:0] B_2_2 = matrix_B[2][2];

// ------------------------
// IP 
// ------------------------

mult_add #(DATA_WIDTH) mult_add_inst (A1,A2,A3,A4,B1,B2,B3,B4,clk,rst,IP_out_data);
endmodule

module mult_add 
#(parameter DATA_WIDTH=8 )(
    input wire signed [DATA_WIDTH-1:0] A1 ,
    input wire signed [DATA_WIDTH-1:0] A2 ,
    input wire signed [DATA_WIDTH-1:0] A3 ,
    input wire signed [DATA_WIDTH-1:0] A4 ,
    input wire signed [DATA_WIDTH-1:0] B1 ,
    input wire signed [DATA_WIDTH-1:0] B2 ,
    input wire signed [DATA_WIDTH-1:0] B3 ,
    input wire signed [DATA_WIDTH-1:0] B4 ,
    input wire clk ,
    input wire rst ,
    output reg signed [DATA_WIDTH*2+3:0] out_data  );

    reg signed [DATA_WIDTH*2-1:0] mult_result_1 ; 
    reg signed [DATA_WIDTH*2-1:0] mult_result_2 ; 
    reg signed [DATA_WIDTH*2-1:0] mult_result_3 ; 
    reg signed [DATA_WIDTH*2-1:0] mult_result_4 ; 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mult_result_1 <= 0;
            mult_result_2 <= 0;
            mult_result_3 <= 0;
            mult_result_4 <= 0;
        end else begin
            mult_result_1 <= A1 * B1 ;
            mult_result_2 <= A2 * B2 ;
            mult_result_3 <= A3 * B3 ;
            mult_result_4 <= A4 * B4 ;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= 0;
        end else begin
            out_data <= mult_result_1 + mult_result_2 + mult_result_3 + mult_result_4 ;
        end
    end
endmodule