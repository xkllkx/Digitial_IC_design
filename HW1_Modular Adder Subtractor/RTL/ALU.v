// 
// Designer: M16121093
//
module ALU(
    input signed [4:0]Din1,
    input signed [4:0]Din2,
    input [1:0]Sel,
    output signed [4:0]tmp
);

reg [4:0]tmp;

always@(Din1 or Din2 or Sel) begin
    case (Sel)
    2'b00   : tmp = Din1 + Din2;
    2'b11   : tmp = Din1 - Din2;
    default : tmp = Din1;
    endcase
end

endmodule