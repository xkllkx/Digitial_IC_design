// 
// Designer: M16121093
//
module MAS_2input(
    input signed [4:0]Din1,
    input signed [4:0]Din2,
    input [1:0]Sel,
    input signed[4:0]Q,
    output [1:0]Tcmp,
    output signed [4:0]TDout,
    output signed [3:0]Dout
);

/*Write your design here*/
wire [4:0]Dout_temp;

ALU ALU0(
    .Din1(Din1),
    .Din2(Din2),
    .Sel(Sel),
    .tmp(TDout)
);

Q_com QC(
    .Din(TDout),
    .Q(Q),
    .SB(Tcmp)
);

ALU ALU1(
    .Din1(TDout),
    .Din2(Q),
    .Sel(Tcmp),
    .tmp(Dout_temp)
);

assign Dout = Dout_temp[3:0];

endmodule