`timescale 1ns/10ps
`define CYCLE    26.3        //modefy by yourself

`ifdef P0//Bulid_Queue,Write 30
   `define EXPECT   "./dat/P0/golden0.dat"
   `define CMD      "./dat/P0/cmd0.dat"
   `define INDEX    "./dat/P0/index0.dat"
   `define KEY      "./dat/P0/value0.dat"
   `define DATA     "./dat/P0/pat0.dat"
   `define DATA_NUM   12     
   `define CMD_NUM    2      
   `define GOLDEN_NUM 12     
   `define End_CYCLE  10000  //modefy by yourself
`elsif P1//Bulid_Queue,Extract_Max,Write 30
   `define EXPECT   "./dat/P1/golden1.dat"
   `define CMD      "./dat/P1/cmd1.dat"
   `define INDEX    "./dat/P1/index1.dat"
   `define KEY      "./dat/P1/value1.dat"
   `define DATA     "./dat/P1/pat1.dat"
   `define DATA_NUM   12    
   `define CMD_NUM    5     
   `define GOLDEN_NUM 9     
   `define End_CYCLE  10000  //modefy by yourself
`elsif P2//Bulid_Queue,Extract_Max,Increase_Value,Write 20
   `define EXPECT   "./dat/P2/golden2.dat"
   `define CMD      "./dat/P2/cmd2.dat"
   `define INDEX    "./dat/P2/index2.dat"
   `define KEY      "./dat/P2/value2.dat"
   `define DATA     "./dat/P2/pat2.dat"
   `define DATA_NUM   12    
   `define CMD_NUM    8     
   `define GOLDEN_NUM 9     
   `define End_CYCLE  10000  //modefy by yourself
`else    //Bulid_Queue,Extract_Max,Increase_Value,Insert_Data,Write 20
   `define EXPECT   "./dat/P3/golden.dat"
   `define CMD      "./dat/P3/cmd.dat"
   `define INDEX    "./dat/P3/index.dat"
   `define KEY      "./dat/P3/value.dat"
   `define DATA     "./dat/P3/pat.dat"
   `define DATA_NUM   12
   `define CMD_NUM    12
   `define GOLDEN_NUM 13
   `define End_CYCLE  10000  //modefy by yourself
`endif

`define SCORE      100

module test;

reg [7:0]data_mem[0:`DATA_NUM - 1];
reg [7:0]expect_mem[0:`GOLDEN_NUM - 1];
reg [2:0]cmd_mem[0:`CMD_NUM - 1];
reg [7:0]index_mem[0:`CMD_NUM - 1];
reg [7:0]value_mem[0:`CMD_NUM - 1];

reg clk = 0;
reg rst;
reg data_valid;
reg [7:0] data;
reg cmd_valid;
reg [2:0] cmd;
reg [7:0] index;
reg [7:0] value;
wire busy;
wire RAM_valid;
wire [7:0]RAM_A;
wire [7:0]RAM_D;
wire done;


MPQ U_MPQ(  .clk(clk),
            .rst(rst),
            .data_valid(data_valid),
            .data(data),
            .cmd_valid(cmd_valid),
            .cmd(cmd),
            .index(index),
            .value(value),
            .busy(busy),
            .RAM_valid(RAM_valid),
            .RAM_A(RAM_A),
            .RAM_D(RAM_D),
            .done(done));

RAM U_RAM (.clk(clk), .RAM_data(RAM_D), .RAM_addr(RAM_A), .RAM_valid(RAM_valid));

initial	$readmemh (`EXPECT, expect_mem);
initial	$readmemb (`CMD,    cmd_mem   );
initial	$readmemh (`INDEX,  index_mem );
initial	$readmemh (`KEY,    value_mem );
initial	$readmemh (`DATA,   data_mem  );


initial begin
   if(expect_mem[0] === 8'dx || cmd_mem[0] == 3'dx|| index_mem[0] === 8'dx || value_mem[0] === 8'dx || data_mem[0]=== 8'dx )begin
      $display(" **************************************               ");
      $display(" **                                  **       |\__||  ");
      $display(" **  Failed to open file!            **      / X,X  | ");
      $display(" **                                  **    /_____   | ");
      $display(" **  Simulation STOP  !!             **   /^ ^ ^ \\  |");
      $display(" **                                  **  |^ ^ ^ ^ |w| ");
      $display(" **************************************   \\m___m__|_|");
      $finish;
   end
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    @(posedge clk);  #2 rst = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk);  #2  rst = 1'b0;
end

reg [22:0] cycle=0;

always @(posedge clk) begin
    cycle=cycle+1;
    if (cycle > `End_CYCLE) begin
         $display(" **************************************               ");
         $display(" **                                  **       |\__||  ");
         $display(" **  Failed waiting valid signal !   **      / X,X  | ");
         $display(" **                                  **    /_____   | ");
         $display(" **  Simulation STOP  !!             **   /^ ^ ^ \\  |");
         $display(" **                                  **  |^ ^ ^ ^ |w| ");
         $display(" **************************************   \\m___m__|_|");
        $finish;
    end
end

integer k;
reg over;
reg [7:0]err = 0;

initial @(posedge done)begin
   for(k=0;k<`GOLDEN_NUM;k=k+1)begin
      if( U_RAM.RAM_M[k] !== expect_mem[k] && expect_mem[k] !== 8'dx) begin
         $display("ERROR at %d:output %h !=expect %h ",k, U_RAM.RAM_M[k], expect_mem[k]);
         err = err+1 ;
		end
      else if ( U_RAM.RAM_M[k] === 8'dx && expect_mem[k] !== 8'dx) begin
         $display("ERROR at %d:output %h !=expect %h ",k, U_RAM.RAM_M[k], expect_mem[k]);
         err = err+1;
      end
   over=1'b1;
   end
	if (err == 0 &&  over ==1'b1  )  begin
      $display(" ****************************               ");
      $display(" **                        **               ");
      $display(" **  Congratulations !!    **               ");
      $display(" **                        **       |\__||  ");
      $display(" **  Simulation PASS !!    **      / O.O  | ");
      $display(" **                        **    /_____   | ");
      $display(" **  Your score =%3d       **   /^ ^ ^ \\  |",`SCORE);
      $display(" **                        **  |^ ^ ^ ^ |w| ");
      $display(" ****************************   \\m___m__|_|");
      #10 $finish;
   end
   else if( over===1'b1 ) begin 
      $display(" ****************************               ");
      $display(" **                        **       |\__||  ");
      $display(" **  OOPS!!                **      / X,X  | ");
      $display(" **                        **    /_____   | ");
      $display(" **  There are %3d errors! **   /^ ^ ^ \\  |", err);
      $display(" **                        **  |^ ^ ^ ^ |W| ");
      $display(" ****************************   \\m___m__|_|");
      #10 $finish;
   end
end

reg [3:0]data_num;
reg [3:0]cmd_num;

always @(negedge clk)begin
	if (rst) begin
      data_num <= 0;
      cmd_num <= 0;
      data_valid <= 0;
      data <= 0;
      cmd_valid <= 0;
      cmd <= 0;
      index <= 0;
      value <= 0;
	end
	else begin
      if(data_num < `DATA_NUM)begin
         data_num <= data_num + 1;
         data_valid <= 1;
         data <= data_mem[data_num];
      end
      else begin
         data_valid <= 0;
         if(cmd_num < `CMD_NUM && busy == 0)begin
            cmd_num <= cmd_num + 1;
            cmd_valid <= 1;
            cmd <= cmd_mem[cmd_num];
            index <= index_mem[cmd_num];
            value <= value_mem[cmd_num];
         end
         else begin
            cmd_valid <= 0;
            cmd <= 0;
            index <= 0;
            value <= 0;
         end
      end
	end
end


endmodule



module RAM (RAM_valid, RAM_data, RAM_addr, clk);
input		RAM_valid;
input	[7:0] RAM_addr;
input	[7:0]	RAM_data;
input		clk;

reg [7:0] RAM_M [0:255];
integer i;

initial begin
	for (i=0; i<=255; i=i+1) RAM_M[i] = 0;
end

always@(negedge clk) 
	if (RAM_valid) RAM_M[ RAM_addr ] <= RAM_data;

endmodule
