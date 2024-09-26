`timescale 1 ns / 1 ps

	module data_src #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);
	
	//BURST数目，必须与axi_dma模块的s2mm一次transfer的数据量大小一致，目前在SDK中设置为128字节
	parameter BURST_NUM = 8'd32;
	
	//BUSRT数目减1，用于生成tlast
	//注意不能用计算公式用于比较判断，仿真正确，但是在Block Design中可能会自动扩位导致出错
	wire [7:0] BURST_NUM_M1;
	assign BURST_NUM_M1 = (BURST_NUM-8'd1);
	
	//导入时钟
	wire clk;
	assign clk = M_AXIS_ACLK;
	
	//导入复位
	wire rstn;
	assign rstn = M_AXIS_ARESETN;
	
	//定义输出端口
	reg tvalid = 1'b0;
	reg [31:0] tdata = 32'd0;
	reg tlast = 1'b0;
	
	assign M_AXIS_TVALID = tvalid;
	assign M_AXIS_TDATA = tdata;
	assign M_AXIS_TLAST = tlast;
	
	assign M_AXIS_TSTRB = 4'b1111;
	
	//burst计数器
	reg [7:0] cnt_burst = 8'd1;
	
	//测试状态机
	reg state = 1'b0;
	
	always @(posedge clk) begin
		if (rstn == 1'b0) begin
			state <= 1'b0;
		end
		else begin
			case (state)
				1'b0: begin
					if (cnt_burst == 8'd10) begin
						state <= 1;
					end
					else begin
						state <= state;
					end
				end
				
				1'b1: begin
					if ({tvalid, M_AXIS_TREADY, cnt_burst} == {1'b1, 1'b1, BURST_NUM}) begin
						state <= 1'b0;
					end
					else begin
						state <= state;
					end
				end
			endcase
		end
	end
	
	//计数器用于控制状态机转移
	always @(posedge clk) begin
		if (rstn == 1'b0) begin
			cnt_burst <= 8'd1;
		end
		else begin
			case (state)
				1'b0: begin
					if (cnt_burst == 8'd10) begin
						cnt_burst <= 8'd1;
					end
					else begin
						cnt_burst <= cnt_burst+8'd1;
					end
				end
				
				1'b1: begin
					if ({tvalid, M_AXIS_TREADY} == 2'b11) begin
						if (cnt_burst == BURST_NUM) begin
							//一次流传输最后1个burst被slave接收
							cnt_burst <= 8'd1;
						end
						else begin
							cnt_burst <= cnt_burst+8'd1;
						end
					end
					else begin
						cnt_burst <= cnt_burst;
					end
				end
				
				default: begin
					cnt_burst <= 8'd1;
				end
			endcase
		end
	end
	
	//输出接口
	always @(posedge clk) begin
		if (rstn == 1'b0) begin
			tvalid <= 1'b0;
			tdata <= 32'd0;
			tlast <= 1'b0;
		end
		else begin
			case (state)
				1'b1: begin
					if ({tvalid, M_AXIS_TREADY, cnt_burst} == {1'b1, 1'b1, BURST_NUM}) begin
						//与状态转移同步
						tvalid <= 1'b0;
					end
					else begin
						tvalid <= 1'b1;
					end
					
					//slave确认接收数据后，数值增1
					if ({tvalid, M_AXIS_TREADY} == 2'b11) begin
						tdata <= tdata+32'd1;
					end
					else begin
						tdata <= tdata;
					end
					
					//倒数第2个burst被接收
					if ({tlast, tvalid, M_AXIS_TREADY, cnt_burst} == {1'b0, 1'b1, 1'b1, BURST_NUM_M1}) begin
						tlast <= 1'b1;
					end
					else if ({tlast, tvalid, M_AXIS_TREADY, cnt_burst} == {1'b1, 1'b1, 1'b1, BURST_NUM}) begin
						//与状态转移同步
						tlast <= 1'b0;
					end
					else begin
						//保持
						tlast <= tlast;
					end
				end
				
				default: begin
					tvalid <= 1'b0;
					tlast <= 1'b0;
					tdata <= tdata;
				end
			endcase
		end
	end
	

	endmodule
