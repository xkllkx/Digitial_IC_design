`timescale 1ns/10ps

// 
// Designer: M16121093
//

module MPQ
#(
parameter DATA_WIDTH=8,
parameter MAX_QUEUE_SIZE=13,
parameter INDEX_WIDTH=4
)(
input clk, // positive edge
input rst, // Active-high asynchronous

input data_valid,
input [DATA_WIDTH-1:0] data,

input cmd_valid,
input [2:0] cmd, // cmd_valid:1 busy:0

input [DATA_WIDTH-1:0] index,
input [DATA_WIDTH-1:0] value,

output RAM_valid,
output [DATA_WIDTH-1:0] RAM_A,
output [DATA_WIDTH-1:0] RAM_D,

output busy,
output done
);

// ------------------------
// Parameters
// ------------------------

//* 1. for loop int
integer i;

//* 2. control flags

//* 3. counter, cursor
reg [INDEX_WIDTH-1:0] queue_size;
reg [INDEX_WIDTH-1:0] cursor, pivot;

//* 4. storage
reg [DATA_WIDTH-1:0] MAX_quene [MAX_QUEUE_SIZE-1:0];

//* 5. state
parameter s_build_queue = 4'd0;
parameter s_extract_max = 4'd1;
parameter s_increase_value = 4'd2;
parameter s_insert_data = 4'd3;
parameter s_write = 4'd4;
parameter s_idle = 4'd5;
parameter s_MAX_HEAPIFY = 4'd6;
parameter s_parse = 4'd7;
parameter s_done = 4'd8;

reg [3:0] state, next_state;

//* 6. wire
wire [INDEX_WIDTH-1:0] Parent;
wire [INDEX_WIDTH:0] Left;
wire [INDEX_WIDTH:0] Right;

// ------------------------
// task or function
// ------------------------

task SWAP;
input [INDEX_WIDTH-1:0] index_1;
input [INDEX_WIDTH-1:0] index_2;
reg [DATA_WIDTH-1:0] temp;
begin
    temp = MAX_quene[index_1];
    MAX_quene[index_1] = MAX_quene[index_2];
    MAX_quene[index_2] = temp;
end
endtask

// task MAX_HEAPIFY;
// input reg [DATA_WIDTH-1:0] i;
// reg [DATA_WIDTH-1:0] l, r, max, temp;
// begin
//     l = (i << 1) + 1; // * 2
//     r = i << 1; // * 2

//     if ((l <= quene_cnt) && (MAX_quene[l] > MAX_quene[i])) max = l;
//     else max = i;

//     if ((r <= quene_cnt) && (MAX_quene[r] > MAX_quene[max])) max = r;

//     if (max != i) begin
//         SWAP(max, i);
//         MAX_HEAPIFY(max);
//     end

//     state_done = 1;
// end
// endtask

task MAX_HEAPIFY;
reg [INDEX_WIDTH-1:0] max;
begin
    max = cursor;

    if ((Left < queue_size) && (MAX_quene[Left] > MAX_quene[cursor])) max = Left;
    // else max = cursor;

    if ((Right < queue_size) && (MAX_quene[Right] > MAX_quene[max])) max = Right;

    if (max != cursor) begin
        SWAP(cursor, max);
        cursor = max;
        // MAX_HEAPIFY(max);
    end
end
endtask

// task BUILD_QUEUE;
// begin
//     for (i = (queue_size >> 1); i >= 1; i = i-1) begin
//         MAX_HEAPIFY(i);
//     end

//     state_done = 1;
// end
// endtask

// task EXTRACT_MAX;
// begin
//     // ! 刪防呆
//     MAX_quene[1] = MAX_quene[queue_size];
//     queue_size = queue_size - 1;
//     MAX_HEAPIFY(1);
// end
// endtask

// task INCREASE_VALUE;
// input [DATA_WIDTH-1:0] i, key;
// reg [DATA_WIDTH-1:0] parent, temp;
// begin
//     if (key >= MAX_quene[i]) begin // ! 刪防呆
//         // parent
//         if (i == 0) parent = 0;
//         else parent = (i >> 1); // i / 2

//         MAX_quene[i] = key;

//         while (i > 1 && MAX_quene[parent] < MAX_quene[i]) begin
//             SWAP(parent , i);
//             i = parent;
//         end
//     end

//     state_done = 1;
// end
// endtask

task INCREASE_VALUE;
begin
    if(MAX_quene[Parent] < MAX_quene[cursor] && Parent < cursor)
        SWAP(Parent , cursor);
end
endtask

// task WRITE_HEAP;
// begin
//     if(RAM_size < queue_size) begin
//         RAM_A = RAM_size;
//         RAM_D = MAX_quene[RAM_size];

//         RAM_size = RAM_size+1;
//     end
//     else RAM_size = RAM_size;
// end
// endtask

// ------------------------
// assign 
// ------------------------

assign busy = (state != s_idle);
assign done = (state == s_done);

assign Parent = (cursor-1'b1) >> 1 ;
assign Left = cursor + cursor + 1'b1;
assign Right = Left + 1'b1;

assign RAM_valid = (state == s_write);
assign RAM_A     = cursor;
assign RAM_D     = MAX_quene[cursor];

// ------------------------
// state 
// ------------------------

always @(posedge clk or posedge rst) begin
    if(rst) begin 
        state <= s_parse;
        // next_state <= s_parse;
    end
    else state <= next_state;
end

always @* begin
    case(state)
    s_parse : next_state = (data_valid) ? s_parse : s_idle;
    s_idle : begin
        if(cmd_valid) begin
            if(cmd == s_increase_value && value < MAX_quene[index-1'b1])
                next_state = s_idle;
            else if(cmd == s_insert_data) next_state = s_increase_value;  
            else next_state = cmd;
        end
        else next_state = s_idle;  
    end
    s_build_queue : next_state =  (pivot == 4'b1111) ?  s_idle : s_MAX_HEAPIFY; // 0-1 = 15 (overflow)
    s_extract_max : next_state = s_build_queue;
    s_increase_value : next_state = (Parent == 0 || MAX_quene[Parent] >= MAX_quene[cursor] || Parent >= cursor) 
                    ? s_idle : s_increase_value;
    s_insert_data : next_state = s_increase_value;
    s_write : next_state = (cursor == queue_size-1) ? s_done : s_write;
    s_MAX_HEAPIFY : begin 
        if(Left < queue_size && MAX_quene[Left] > MAX_quene[cursor] || Right < queue_size && MAX_quene[Right] > MAX_quene[cursor]) 
            next_state = s_MAX_HEAPIFY;
        else next_state = s_build_queue;
    end
    endcase
end

// ------------------------
// Calculate 
// ------------------------

always @(posedge clk or posedge rst) begin
    if (rst) begin
        queue_size <= 0;
        cursor <= 0;
        pivot <= 0;
        for (i = 0; i < MAX_QUEUE_SIZE; i = i+1) begin
            MAX_quene[i] <= 0;
        end
    end
    else begin
        case(state)
        s_done :  begin
            cursor <= 0; 
            queue_size <= 0;
            pivot <= 0;
            for(i = 0 ; i < MAX_QUEUE_SIZE ; i = i+1) begin
                MAX_quene[i] <= 0;
            end
        end
        s_parse : begin
            if(data_valid) begin 
                // MAX_quene[queue_size] <= data;
                MAX_quene[cursor] <= data;
                queue_size <= queue_size + 1'b1;
                cursor <= cursor + 1'b1;
            end
            // else queue_size <= queue_size;
        end
        s_idle : begin
            pivot <= (queue_size >> 1) - 1'b1;
            if(cmd_valid && cmd == s_increase_value && value >= MAX_quene[index-1'b1]) begin
                MAX_quene[index-1'b1] <= value;
                cursor <= index - 1'b1;
            end
            else if(cmd_valid && cmd == s_insert_data) begin
                MAX_quene[queue_size] <= value;
                cursor <= queue_size;
                queue_size <= queue_size + 1'b1;
            end
            else cursor <= 0;
        end
        s_build_queue : begin
            // BUILD_QUEUE();

            // MAX_HEAPIFY(pivot , queue_size);
            cursor <= pivot;
            pivot <= pivot - 1'b1;
        end
        s_MAX_HEAPIFY : MAX_HEAPIFY();
        s_extract_max : begin
            // EXTRACT_MAX();

            SWAP(0, queue_size-1'b1);
            MAX_quene[queue_size-1'b1] <= 0;
            queue_size <= queue_size - 1'b1;
            pivot <= 0;
            // MAX_HEAPIFY(0, queue_size-1);
        end
        s_increase_value : begin // s_insert_data
            // INCREASE_VALUE(index, value)
            INCREASE_VALUE();
            cursor <= (cursor-1'b1) >> 1;
        end
        s_write: begin
            // WRITE_HEAP();
            cursor <= cursor + 1'b1;
        end
        endcase
    end
end

endmodule
