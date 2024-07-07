`timescale 1ns/10ps
// `define SDFFILE    "../SYN/SET_syn.sdf"    // Modify your sdf file name here
// `define cycle 25.0
`define cycle 18.3
// `define terminate_cycle 400000 // Modify your terminate cycle here
`define terminate_cycle 200000 // Modify your terminate cycle here

module testfixture1;

`define in_pattern1 "in1.dat"
`define in_pattern2 "in2.dat"
`define in_pattern3 "in3.dat"
`define  result1 "out1.dat"
`define  result2 "out2.dat"
`define  result3 "out3.dat"
`define  shape1 "mx_shape1.dat"
`define  shape2 "mx_shape2.dat"
`define  shape3 "mx_shape3.dat"
parameter total_test = 100;//number of total cases
reg clk = 0;
reg rst;
reg [7:0] in_data;
wire busy;
wire valid;
wire [19:0] out_data;
reg col_end,row_end;
integer err_cnt;
wire is_legal,change_row;
reg [7:0] in_mem [0:10000],in_mem2 [0:10000],in_mem3 [0:10000];//max input size
reg [19:0] out_mem [0:10000],out_mem2 [0:10000],out_mem3 [0:10000];//max output size
reg [3:0] shape_mem[0:4 * total_test - 1],shape_mem2[0:4 * total_test - 1],shape_mem3[0:4 * total_test - 1];

`ifdef SDF
initial $sdf_annotate(`SDFFILE, u_set);
`endif

integer read_temp ;
initial begin
	$timeformat(-9, 1, " ns", 9); //Display time in nanoseconds
	$readmemh(`in_pattern1, in_mem);
	$readmemh(`in_pattern2, in_mem2);
	$readmemh(`in_pattern3, in_mem3);
	$readmemh(`result1, out_mem);
	$readmemh(`result2, out_mem2);
	$readmemh(`result3, out_mem3);
	$readmemh(`shape1, shape_mem);
	$readmemh(`shape2, shape_mem2);
	$readmemh(`shape3, shape_mem3);
	$display("--------------------------- [ Simulation START !! ] ---------------------------");
end



always #(`cycle/2) clk = ~clk;



MM u_set(.clk(clk),
        .rst(rst),
        .in_data(in_data),
        .col_end(col_end),
        .row_end(row_end),
		.busy(busy),
		.valid(valid),
        .is_legal(is_legal),
        .out_data(out_data),
		.change_row(change_row));

integer k,current_k,shape_mem_index,mx2_size,mx1_size;
integer p,check_index,out_num,total,p_n,score,total_error;
initial begin
    rst = 0;
	err_cnt = 0;
	k = 0;
	shape_mem_index = 0;
	current_k = 0;
	out_num = 0;
	total = 0;
	score = 0;
# `cycle;     
	rst = 1;
#(`cycle*3);
	rst = 0;
	for(p = 0; p<total_test; p = p+1) begin
		mx1_size = shape_mem[shape_mem_index+0] * shape_mem[shape_mem_index+1];
		mx2_size = shape_mem[shape_mem_index+2] * shape_mem[shape_mem_index+3];
		for (k = 0; k<mx1_size+mx2_size; k = k+1) begin
			@(negedge clk);
				#(`cycle/4)	wait(busy == 0);
					if(k < mx1_size)begin
						if(k % shape_mem[shape_mem_index+1] == shape_mem[shape_mem_index+1] - 1)col_end = 1;
						else col_end = 0;
						if(k % mx1_size == mx1_size - 1)row_end = 1;
						else row_end = 0;	
					end
					else begin
						if((k - mx1_size) % shape_mem[shape_mem_index+3] == shape_mem[shape_mem_index+3] - 1)col_end = 1;
						else col_end = 0;
						if((k - mx1_size) % mx2_size == mx2_size - 1)row_end = 1;
						else row_end = 0;	
					end
					in_data = in_mem[current_k+k];                
		end
		current_k = current_k+k;
		@(negedge clk); begin
			row_end = 0;
			col_end = 0;
		end
		begin:Test
			for(check_index=0;check_index<shape_mem[shape_mem_index+0]*shape_mem[shape_mem_index+3];check_index=check_index+1)begin
				#(`cycle)
				wait (valid == 1);
				@(negedge clk); begin
					if(shape_mem[shape_mem_index+1] != shape_mem[shape_mem_index+2])begin
						if(!is_legal)begin
							$display(" 1:Pattern %d is PASS !", total + check_index);
						end
						else begin
							$display(" 2:Pattern %d is FAIL !. Expected is_legal = %d, but the Response is_legal = %d !!", total + check_index,0,is_legal);//check
							err_cnt = err_cnt + 1;					
						end
						total = total + 1 - shape_mem[shape_mem_index+0]*shape_mem[shape_mem_index+3];
						out_num = out_num - shape_mem[shape_mem_index+0]*shape_mem[shape_mem_index+3];
						disable Test;
					end
					else if (out_data === out_mem[out_num + check_index])
						if(check_index % shape_mem[shape_mem_index+3] == shape_mem[shape_mem_index+3] - 1)begin
							if(change_row == 1)begin
								$display(" 4:Pattern %d is PASS !", total + check_index);						
							end
							else  begin
								$display(" 3:Pattern %d out_data is PASS ! but change_row is FAIL !. Expected 1 but get %d", total + check_index,change_row);
								err_cnt = err_cnt + 1;
							end
						end
						else begin
							if(change_row == 0)begin
								$display(" 6:Pattern %d is PASS !", total + check_index); //Expected value = %d, but the Response value = %d !!", total + check_index, out_mem[out_num + check_index], out_data						
							end
							else  begin
								$display(" 5:Pattern %d out_data is PASS ! but change_row is FAIL !. Expected 0 but get 1", total + check_index);
								err_cnt = err_cnt + 1;
							end
						end
						
					else begin
						$display(" 7:Pattern %d is FAIL !. Expected value = %d, but the Response value = %d !! ", total + check_index, out_mem[out_num + check_index], out_data);
						err_cnt = err_cnt + 1;
					end
				end
			end
		end
		out_num = out_num + shape_mem[shape_mem_index+0]*shape_mem[shape_mem_index+3];
		total = total + shape_mem[shape_mem_index+0]*shape_mem[shape_mem_index+3];
		shape_mem_index = shape_mem_index + 4;
	end
	total_error = err_cnt;
	if(err_cnt == 0)begin
		score = 40;
		$display("Pattern 1 pass");
	end
	err_cnt = 0;
	k = 0;
	shape_mem_index = 0;
	current_k = 0;
	out_num = 0;

	for(p = 0; p<total_test; p = p+1) begin
		mx1_size = shape_mem2[shape_mem_index+0] * shape_mem2[shape_mem_index+1];
		mx2_size = shape_mem2[shape_mem_index+2] * shape_mem2[shape_mem_index+3];
		for (k = 0; k<mx1_size+mx2_size; k = k+1) begin
			@(negedge clk);
				#(`cycle/4)	wait(busy == 0);
					if(k < mx1_size)begin
						if(k % shape_mem2[shape_mem_index+1] == shape_mem2[shape_mem_index+1] - 1)col_end = 1;
						else col_end = 0;
						if(k % mx1_size == mx1_size - 1)row_end = 1;
						else row_end = 0;	
					end
					else begin
						if((k - mx1_size) % shape_mem2[shape_mem_index+3] == shape_mem2[shape_mem_index+3] - 1)col_end = 1;
						else col_end = 0;
						if((k - mx1_size) % mx2_size == mx2_size - 1)row_end = 1;
						else row_end = 0;	
					end
					in_data = in_mem2[current_k+k];                
		end
		current_k = current_k+k;
		@(negedge clk); begin
			row_end = 0;
			col_end = 0;
		end
		begin:Test2
			for(check_index=0;check_index<shape_mem2[shape_mem_index+0]*shape_mem2[shape_mem_index+3];check_index=check_index+1)begin
				#(`cycle)
				wait (valid == 1);
				@(negedge clk); begin
					if(shape_mem2[shape_mem_index+1] != shape_mem2[shape_mem_index+2])begin
						if(!is_legal)begin
							$display(" 1:Pattern %d is PASS !", total + check_index);
						end
						else begin
							$display(" 2:Pattern %d is FAIL !. Expected is_legal = %d, but the Response is_legal = %d !!", total + check_index,0,is_legal);//check
							err_cnt = err_cnt + 1;					
						end
						total = total + 1 - shape_mem2[shape_mem_index+0]*shape_mem2[shape_mem_index+3];
						out_num = out_num - shape_mem2[shape_mem_index+0]*shape_mem2[shape_mem_index+3];
						disable Test2;
					end
					else if (out_data === out_mem2[out_num + check_index])
						if(check_index % shape_mem2[shape_mem_index+3] == shape_mem2[shape_mem_index+3] - 1)begin
							if(change_row == 1)begin
								$display(" 4:Pattern %d is PASS !", total + check_index);						
							end
							else  begin
								$display(" 3:Pattern %d out_data is PASS ! but change_row is FAIL !. Expected 1 but get %d", total + check_index,change_row);
								err_cnt = err_cnt + 1;
							end
						end
						else begin
							if(change_row == 0)begin
								$display(" 6:Pattern %d is PASS !", total + check_index); //Expected value = %d, but the Response value = %d !!", total + check_index, out_mem[out_num + check_index], out_data						
							end
							else  begin
								$display(" 5:Pattern %d out_data is PASS ! but change_row is FAIL !. Expected 0 but get 1", total + check_index);
								err_cnt = err_cnt + 1;
							end
						end
						
					else begin
						$display(" 7:Pattern %d is FAIL !. Expected value = %d, but the Response value = %d !! ", total + check_index, out_mem2[out_num + check_index], out_data);
						err_cnt = err_cnt + 1;
					end
				end
			end
		end
		out_num = out_num + shape_mem2[shape_mem_index+0]*shape_mem2[shape_mem_index+3];
		total = total + shape_mem2[shape_mem_index+0]*shape_mem2[shape_mem_index+3];
		shape_mem_index = shape_mem_index + 4;
	end
	total_error = total_error + err_cnt;
	if(err_cnt == 0)begin
		score = 70;
		$display("Pattern 2 pass");
	end
	err_cnt = 0;
	k = 0;
	shape_mem_index = 0;
	current_k = 0;
	out_num = 0;

	for(p = 0; p<total_test; p = p+1) begin
		mx1_size = shape_mem3[shape_mem_index+0] * shape_mem3[shape_mem_index+1];
		mx2_size = shape_mem3[shape_mem_index+2] * shape_mem3[shape_mem_index+3];
		for (k = 0; k<mx1_size+mx2_size; k = k+1) begin
			@(negedge clk);
				#(`cycle/4)	wait(busy == 0);
					if(k < mx1_size)begin
						if(k % shape_mem3[shape_mem_index+1] == shape_mem3[shape_mem_index+1] - 1)col_end = 1;
						else col_end = 0;
						if(k % mx1_size == mx1_size - 1)row_end = 1;
						else row_end = 0;	
					end
					else begin
						if((k - mx1_size) % shape_mem3[shape_mem_index+3] == shape_mem3[shape_mem_index+3] - 1)col_end = 1;
						else col_end = 0;
						if((k - mx1_size) % mx2_size == mx2_size - 1)row_end = 1;
						else row_end = 0;	
					end
					in_data = in_mem3[current_k+k];                
		end
		current_k = current_k+k;
		@(negedge clk); begin
			row_end = 0;
			col_end = 0;
		end
		begin:Test3
			for(check_index=0;check_index<shape_mem3[shape_mem_index+0]*shape_mem3[shape_mem_index+3];check_index=check_index+1)begin
				#(`cycle)
				wait (valid == 1);
				@(negedge clk); begin
					if(shape_mem3[shape_mem_index+1] != shape_mem3[shape_mem_index+2])begin
						if(!is_legal)begin
							$display(" 1:Pattern %d is PASS !", total + check_index);
						end
						else begin
							$display(" 2:Pattern %d is FAIL !. Expected is_legal = %d, but the Response is_legal = %d !!", total + check_index,0,is_legal);//check
							err_cnt = err_cnt + 1;					
						end
						total = total + 1 - shape_mem3[shape_mem_index+0]*shape_mem3[shape_mem_index+3];
						out_num = out_num - shape_mem3[shape_mem_index+0]*shape_mem3[shape_mem_index+3];
						disable Test3;
					end
					else if (out_data === out_mem3[out_num + check_index])
						if(check_index % shape_mem3[shape_mem_index+3] == shape_mem3[shape_mem_index+3] - 1)begin
							if(change_row == 1)begin
								$display(" 4:Pattern %d is PASS !", total + check_index);						
							end
							else  begin
								$display(" 3:Pattern %d out_data is PASS ! but change_row is FAIL !. Expected 1 but get %d", total + check_index,change_row);
								err_cnt = err_cnt + 1;
							end
						end
						else begin
							if(change_row == 0)begin
								$display(" 6:Pattern %d is PASS !", total + check_index); //Expected value = %d, but the Response value = %d !!", total + check_index, out_mem[out_num + check_index], out_data						
							end
							else  begin
								$display(" 5:Pattern %d out_data is PASS ! but change_row is FAIL !. Expected 0 but get 1", total + check_index);
								err_cnt = err_cnt + 1;
							end
						end
						
					else begin
						$display(" 7:Pattern %d is FAIL !. Expected value = %d, but the Response value = %d !! ", total + check_index, out_mem3[out_num + check_index], out_data);
						err_cnt = err_cnt + 1;
					end
				end
			end
		end
		out_num = out_num + shape_mem3[shape_mem_index+0]*shape_mem3[shape_mem_index+3];
		total = total + shape_mem3[shape_mem_index+0]*shape_mem3[shape_mem_index+3];
		shape_mem_index = shape_mem_index + 4;
	end
	total_error = total_error + err_cnt;
	if(err_cnt == 0)begin
		score = 100;
		$display("Pattern 3 pass");
	end









#(`cycle*2); 
     $display("--------------------------- Simulation FINISH !!---------------------------");
	 $display("score = %d/100",score);
     if (err_cnt) begin 
     	$display("============================================================================");
     	$display("\n (T_T) FAIL!! The simulation result is FAIL!!! there were %d errors at all.\n", err_cnt);
	$display("============================================================================");
	end
     else begin 
     	$display("============================================================================");
	$display("\n \\(^o^)/ CONGRATULATIONS!!  The simulation result is PASS!!!\n");
	$display("============================================================================");
	end
$stop;
$finish;
end


always@(err_cnt) begin
	if (err_cnt == 100) begin
		$display("score = %d/100",score);
	$display("============================================================================");
     	$display("\n (>_<) FAIL!! The simulation FAIL result is too many ! Please check your code @@ \n");
	$display("============================================================================");
	$stop;
	$finish;
	end
end

initial begin 
	#`terminate_cycle;
	$display("score = %d/100",score);
	$display("================================================================================================================");
	$display("--------------------------- (/`n`)/ ~#  There was something wrong with your code !! ---------------------------"); 
	$display("--------------------------- The simulation can't finished!!, Please check it !!! ---------------------------"); 
	$display("================================================================================================================");
	$stop;
	$finish;
end


endmodule
