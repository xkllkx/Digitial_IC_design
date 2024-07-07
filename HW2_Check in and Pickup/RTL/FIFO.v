// 
// Designer: M16121093
//
module FIFO
// Params
#(
    parameter data_len = 8,
    parameter tmp_len = 16
)

// Ports
(
    input clk , rst,
    input ready,

    input  [data_len-1:0] in,
    output [data_len-1:0] out,

    output  valid,
    output  done
);

reg [data_len-1:0] tmp [tmp_len-1:0];

integer counter = 0, i = 0;

// state -----------------------------------------------------------------
parameter s_idle = 3'd0;
parameter s_read = 3'd1; // passenger, thing 一起讀
parameter s_write = 3'd2;
parameter s_done = 3'd3;

reg [2:0] state, next_state;

always @(posedge clk) begin
    if(rst) state <= s_idle;
    else state <= next_state;
end

always @* begin
    if(rst) next_state = s_idle;
    else begin
        case(state)
            s_idle : next_state = (ready) ? s_read : s_idle;
            s_read : next_state = (in == 8'd36) ? s_write : s_read; // $
            s_write : next_state = (counter <= 1) ? s_done : s_write;
            s_done : next_state = (rst) ? s_idle : s_done;
        endcase
    end
end

assign valid = (state == s_write) ? 1'b1 : 1'b0;
assign done  = (state == s_done) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------

always@(posedge clk) begin
    if(rst) begin
        for(i = tmp_len-1; i >= 0; i = i-1) begin
            tmp[i] = 0;
        end
        counter = 0;
    end
    else begin
        case(state)
            s_read : begin // ! push
                if(in > 8'd64) begin
                    tmp[counter] = in; //  ... 3 2 1 0
                    counter = counter + 1;
                end
                else counter = counter;
            end

            s_write : begin
                for(i = 0; i < counter-1; i = i+1) begin
                    tmp[i] = tmp[i+1];
                    tmp[i+1] = 0;
                end
                
                counter = counter - 1;
            end
            
            default : counter = counter;
        endcase
    end
end

assign out = (state == s_write) ? tmp[0] : {data_len{1'dx}};

endmodule