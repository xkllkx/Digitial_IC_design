// 
// Designer: M16121093
//
module Q_com(
    input signed [4:0]Din,
    input signed [4:0]Q,
    output [1:0]SB
);

assign SB = {Din >= Q, Din >= 0}; // MSB | LSB

endmodule