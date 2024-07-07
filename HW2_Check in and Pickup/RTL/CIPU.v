//
// Designer: M16121093
//
module CIPU(
    input       clk, 
    input       rst,
    input       [7:0]people_thing_in,
    input       ready_fifo,
    input       ready_lifo,
    input       [7:0]thing_in,
    input       [3:0]thing_num,
    output      valid_fifo,
    output      valid_lifo,
    output      valid_fifo2,
    output      [7:0]people_thing_out,
    output      [7:0]thing_out,
    output      done_thing,
    output      done_fifo,
    output      done_lifo,
    output      done_fifo2
    );
    
    FIFO #(
        .data_len(8), 
        .tmp_len(16)
        )
        passenger(
        .clk(clk),
        .rst(rst),
        .ready(ready_fifo),
        .in(people_thing_in),
        .out(people_thing_out),
        .valid(valid_fifo),
        .done(done_fifo)
    );

    LIFO #(
        .data_len(8), 
        .tmp_len(16),
        .pop_len(4)
        )
        thing(
        .clk(clk),
        .rst(rst),
        .ready(ready_lifo),
        .in(thing_in),
        .out(thing_out),
        .pop_num(thing_num),
        .valid_lifo(valid_lifo),
        .done_thing(done_thing),
        .done_lifo(done_lifo),
        .valid_fifo(valid_fifo2),
        .done_fifo(done_fifo2)
    );
    
    endmodule