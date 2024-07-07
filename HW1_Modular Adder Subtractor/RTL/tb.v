`timescale 1ns/10ps
module test;

reg [4:0]Din1,Din2,Q;
reg [1:0]Sel;
reg clk;
wire [3:0]Dout;
reg [4:0]ALU_GOLD;
reg [3:0]GOLD;
wire[4:0]ALU_out;
integer i, error;
reg [1:0]GOLD_Comparater;
wire [1:0]Comparater;
reg [19:0]ALU_pattern[0:199];
reg [23:0]pattern[0:199];
reg [1:0] flag;

reg [23:0]t;
wire [4:0]TDout;
MAS_2input U0(Din1,Din2,Sel,Q,Comparater,TDout,Dout);

// ! waveform
initial begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, test);    //tb模块名称
end

initial begin
    clk = 1'b0;
    flag = 2'b00;
    forever #2.5 clk = ~clk;
end

initial begin
    $readmemh("ALU_data.dat",ALU_pattern);
    $readmemh("MAS_2input_data.dat",pattern);
    $display("----------------------------------------");
    $display("----------------Stage 1-----------------");
    $display("--------- ALU Simulation Begin ---------");
    $display("----------------------------------------");
    error=0;
    for(i=0;i<200;i=i+1) begin
        t = ALU_pattern[i];
        @(negedge clk);
        Din1 = {1'b0,t[19:16]};
        Din2 = {1'b0,t[15:12]};
        Sel = t[9:8];
        ALU_GOLD = t[4:0];

        @(posedge clk);
        if(TDout !== ALU_GOLD) begin
            if(Sel==0)
                $display("ERROR: %d + %d should be %d ,not %d\n",Din1,Din2,GOLD,ALU_out);
            else if(Sel==2'b11)
                $display("ERROR: %d - %d should be %d ,not %d\n",Din1,Din2,GOLD,ALU_out);
            error = error+1;
        end
    end
    if(error==0) begin
        $display("----------------------------------------");
        $display("-------- ALU Simulation Success --------");
        $display("----------------------------------------");
        $display("----------------------------------------");
        $display("--------- ALU Simulation  End  ---------");
        $display("----------------------------------------\n");
        error = 0;
        flag = 2'b01;
    end
    else begin
        $display("Please check your code.");
        $display("ERROR Count: %d\n",error);
        $display("----------------------------------------");
        $display("--------- ALU Simulation  End  ---------");
        $display("----------------------------------------\n");
        $finish;
    end
    
    $display("----------------------------------------");
    $display("----------------Stage 2-----------------");
    $display("----- Comparater Simulation Begin -----");
    $display("----------------------------------------");
    error = 0;
    for(i=0;i<200;i=i+1) begin
        t = pattern[i];
        @(negedge clk);
        Din1 = {1'b0,t[23:20]};
        Din2 = {1'b0,t[19:16]};
        Q = {1'b0,t[15:12]};
        Sel = t[9:8];
        GOLD = t[7:4];
        GOLD_Comparater = t[1:0];
        @(posedge clk);
        if(Comparater !== GOLD_Comparater) begin
            if(Sel==0)
                $display("ERROR: %d + %d mod %d Comparater should be %b ,not %b\n",Din1,Din2,Q,GOLD_Comparater,Comparater);
            else if(Sel==2'b11)
                $display("ERROR: %d - %d mod %d Comparater should be %b ,not %b\n",Din1,Din2,Q,GOLD_Comparater,Comparater);
            error = error+1;
        end
    end
    if(error==0) begin
        $display("----------------------------------------");
        $display("---- Comparater Simulation Success -----");
        $display("----------------------------------------");
        $display("----------------------------------------");
        $display("------ Comparater Simulation End -------");
        $display("----------------------------------------\n");
        flag = 2'b10;
    end
    else begin
        $display("Please check your code.");
        $display("ERROR Count: %d\n",error);
        $display("----------------------------------------");
        $display("------ Comparater Simulation End -------");
        $display("----------------------------------------\n");
    end

    $display("----------------Stage 3-----------------");
    $display("----------------------------------------");
    $display("----- 2-input MAS Simulation Begin -----");
    $display("----------------------------------------");
    error = 0;
    for(i=0;i<200;i=i+1) begin
        t = pattern[i];
        @(negedge clk);
        Din1 = {1'b0,t[23:20]};
        Din2 = {1'b0,t[19:16]};
        Q = {1'b0,t[15:12]};
        Sel = t[9:8];
        GOLD = t[7:4];
        GOLD_Comparater = t[1:0];
        @(posedge clk);
        if(Dout !== GOLD) begin
            if(Sel==0)
                $display("ERROR: %d + %d mod %d should be %d ,not %d\n",Din1,Din2,Q,GOLD,Dout);
            else if(Sel==2'b11)
                $display("ERROR: %d - %d mod %d should be %d ,not %d\n",Din1,Din2,Q,GOLD,Dout);
            error = error+1;
        end
    end
    if(error==0) begin
        $display("----------------------------------------");
        $display("---- 2-input MAS Simulation Success ----");
        $display("----------------------------------------");
        $display("----------------------------------------");
        $display("------ 2-input MAS Simulation End ------");
        $display("----------------------------------------\n");

        if (flag ==2'b10)
        begin
        $display("#                                            /|__/|");
        $display("####################################       / O,O  |");
        $display("###            Pass!             ###     /_____   |");
        $display("####################################    /^ ^ ^ \\  |");
        $display("#                                      |^ ^ ^ ^ |w|");
        $display("#                                       \\m___m__|_|");
        end
    end

    else begin
        $display("Please check your code.");
        $display("ERROR Count: %d",error);
        $display("----------------------------------------");
        $display("------ 2-input MAS Simulation End ------");
        $display("----------------------------------------\n");
    end

    @(posedge clk);
        $finish;
    
end

endmodule
