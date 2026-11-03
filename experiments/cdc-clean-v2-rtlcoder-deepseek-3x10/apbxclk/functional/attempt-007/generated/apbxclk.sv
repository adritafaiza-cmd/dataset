Sure, here is the complete Verilog code for the APB clock-domain bridge module:

```
module apbxclk #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		parameter [0:0]	OPT_REGISTERED = 1'b0,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH
	) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	reg [AW-1:0] S_APB_PADDR_reg;
	reg [DW-1:0] S_APB_PWDATA_reg;
	reg [DW/8-1:0] S_APB_PWSTRB_reg;
	reg [2:0] S_APB_PPROT_reg;
	reg S_APB_PWRITE_reg;
	reg S_APB_PSEL_reg;
	reg S_APB_PENABLE_reg;
	reg M_APB_PSEL_reg;
	reg M_APB_PENABLE_reg;
	reg [AW-1:0] M_APB_PADDR_reg;
	reg [DW-1:0] M_APB_PWDATA_reg;
	reg [DW/8-1:0] M_APB_PWSTRB_reg;
	reg [2:0] M_APB_PPROT_reg;
	reg M_APB_PWRITE_reg;
	reg M_PRESETn_reg;

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 1'b0;
			S_APB_PADDR_reg <= 0;
			S_APB_PWDATA_reg <= 0;
			S_APB_PWSTRB_reg <= 0;
			S_APB_PPROT_reg <= 0;
			S_APB_PWRITE_reg <= 1'b0;
			S_APB_PSEL_reg <= 1'b0;
			S_APB_PENABLE_reg <= 1'b0;
			M_APB_PSEL_reg <= 1'b0;
			M_APB_PENABLE_reg <= 1'b0;
			M_APB_PADDR_reg <= 0;
			M_APB_PWDATA_reg <= 0;
			M_APB_PWSTRB_reg <= 0;
			M_APB_PPROT_reg <= 0;
			M_APB_PWRITE_reg <= 1'b0;
			M_PRESETn_reg <= 1'b0;
		end else begin
			if (S_APB_PSEL && !S_APB_PENABLE) begin
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA <= M_APB_PRDATA;
				S_APB_PSLVERR <= M_APB_PSLVERR;
				S_APB_PADDR_reg <= S_APB_PADDR;
				S_APB_PWDATA_reg <= S_APB_PWDATA;
				S_APB_PWSTRB_reg <= S_APB_PWSTRB;
				S_APB_PPROT_reg <= S_APB_PPROT;
				S_APB_PWRITE_reg <= S_APB_PWRITE;
				S_APB_PSEL_reg <= 1'b1;
				S_APB_PENABLE_reg <= 1'b1;
				M_APB_PSEL_reg <= 1'b1;
				M_APB_PENABLE_reg <= 1'b1;
				M_APB_PADDR_reg <= S_APB_PADDR;
				M_APB_PWDATA_reg <= S_APB_PWDATA;
				M_APB_PWSTRB_reg <= S_APB_PWSTRB;
				M_APB_PPROT_reg <= S_APB_PPROT;
				M_APB_PWRITE_reg <= S_APB_PWRITE;
				M_PRESETn_reg <= 1'b1;
			end else if (S_APB_PSEL && S_APB_PENABLE && M_APB_PREADY) begin
				S_APB_PREADY <= 1'b0;
				S_APB_PRDATA <= 0;
				S_APB_PSLVERR <= 1'b0;
				S_APB_PADDR_reg <= 0;
				S_APB_PWDATA_reg <= 0;
				S_APB_PWSTRB_reg <= 0;
				S_APB_PPROT_reg <= 0;
				S_APB_PWRITE_reg <= 1'b0;
				S_APB_PSEL_reg <= 1'b0;
				S_APB_PENABLE_reg <= 1'b0;
				M_APB_PSEL_reg <= 1'b0;
				M_APB_PENABLE_reg <= 1'b0;
				M_APB_PADDR_reg <= 0;
				M_APB_PWDATA_reg <= 0;
				M_APB_PWSTRB_reg <= 0;
				M_APB_PPROT_reg <= 0;
				M_APB_PWRITE_reg <= 1'b0;
				M_PRESETn_reg <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
				S_APB_PRDATA <= 0;
				S_APB_PSLVERR <= 1'b0;
				S_APB_PADDR_reg <= S_APB_PADDR_reg;
				S_APB_PWDATA_reg <= S_APB_PWDATA_reg;
				S_APB_PWSTRB_reg <= S_APB_PWSTRB_reg;
				S_APB_PPROT_reg <= S_APB_PPROT_reg;
				S_APB_PWRITE_reg <= S_APB_PWRITE_reg;
				S_APB_PSEL_reg <= S_APB_PSEL_reg;
				S_APB_PENABLE_reg <= S_APB_PENABLE_reg;
				M_APB_PSEL_reg <= M_APB_PSEL_reg;
				M_APB_PENABLE_reg <= M_APB_PENABLE_reg;
				M_APB_PADDR_reg <= M_APB_PADDR_reg;
				M_APB_PWDATA_reg <= M_APB_PWDATA_reg;
				M_APB_PWSTRB_reg <= M_APB_PWSTRB_reg;
				M_APB_PPROT_reg <= M_APB_PPROT_reg;
				M_APB_PWRITE_reg <= M_APB_PWRITE_reg;
				M_PRESETn_reg <= M_PRESETn_reg;
			end
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (!M_PRESETn_reg) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= 0;
			M_APB_PWDATA <= 0;
			M_APB_PWSTRB <= 0;
			M_APB_PPROT <= 0;
			M_APB_PWRITE <= 1'b0;
			M_PRESETn <= 1'b0;
		end else begin
			if (M_APB_PSEL_reg && !M_APB_PENABLE_reg) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				M_APB_PADDR <= M_APB_PADDR_reg;
				M_APB_PWDATA <= M_APB_PWDATA_reg;
				M_APB_PWSTRB <= M_APB_PWSTRB_reg;
				M_APB_PPROT <= M_APB_PPROT_reg;
				M_APB_PWRITE <= M_APB_PWRITE_reg;
				M_PRESETn <= 1'b1;
			end else if (M_APB_PSEL_reg && M_APB_PENABLE_reg && S_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				M_APB_PADDR <= 0;
				M_APB_PWDATA <= 0;
				M_APB_PWSTRB <= 0;
				M_APB_PPROT <= 0;
				M_APB_PWRITE <= 1'b0;
				M_PRESETn <= 1'b0;
			end else begin
				M_APB_PSEL <= M_APB_PSEL;
				M_APB_PENABLE <= M_APB_PENABLE;
				M_APB_PADDR <= M_APB_PADDR;
				M_APB_PWDATA <= M_APB_PWDATA;
				M_APB_PWSTRB <= M_APB_PWSTRB;
				M_APB_PPROT <= M_APB_PPROT;
				M_APB_PWRITE <= M_APB_PWRITE;
				M_PRESETn <= M_PRESETn;
			end
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Copyright (c) 2017, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

`timescale 1 ns / 1 ps

module avalon_mm_bridge_avalon_slave_0_rdata_reg
(
    input wire clk,
    input wire reset_n,
    input wire [31:0] wr_data,
    input wire wr_en,
    input wire rd_en,
    output wire [31:0] rd_data
);

reg [31:0] rdata_reg;

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        rdata_reg <= 32'h0;
    end
    else begin
        if (wr_en) begin
            rdata_reg <= wr_data;
        end
        else if (rd_en) begin
            rdata_reg <= rdata_reg;
        end
    end
end

assign rd_data = rdata_reg;

endmodule

module avalon_mm_bridge_avalon_slave_0_wdata_reg
(
    input wire clk,
    input wire reset_n,
    input wire [31:0] wr_data,
    input wire wr_en,
    output wire [31:0] rd_data
);

reg [31:0] wdata_reg;

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        wdata_reg <= 32'h0;
    end
    else begin
        if (wr_en) begin
            wdata_reg <= wr_data;
        end
        else begin
            wdata_reg <= wdata_reg;
        end
    end
end

assign rd_data = wdata_reg;

endmodule

module avalon_mm_bridge_avalon_slave_0_control_reg
(
    input wire clk,
    input wire reset_n,
    input wire [31:0] wr_data,
    input wire wr_en,
    output wire [31:0] rd_data
);

reg [31:0] control_reg;

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        control_reg <= 32'h0;
    end
    else begin
        if (wr_en) begin
            control_reg <= wr_data;
        end
        else begin
            control_reg <= control_reg;
        end
    end
end

assign rd_data = control_reg;

endmodule

module avalon_mm_bridge_avalon_slave_0
(
    input wire clk,
    input wire reset_n,
    input wire [31:0] avs_address,
    input wire [31:0] avs_writedata,
    input wire avs_write,
    input wire avs_read,
    output wire [31:0] avs_readdata,
    output wire avs_waitrequest,
    output wire [3:0] avs_byteenable,
    output wire avs_readdatavalid,
    output wire avs_writeresponsevalid,
    output wire [1:0] avs_writeresponse,
    input wire [31:0] avm_readdata,
    input wire avm_waitrequest,
    input wire [3:0] avm_byteenable,
    input wire avm_readdatavalid,
    input wire [1:0] avm_writeresponse,
    output wire [31:0] avm_address,
    output wire [31:0] avm_writedata,
    output wire avm_write,
    output wire avm_read,
    input wire [31:0] avm_readdatavalid,
    input wire [1:0] avm_writeresponse
);

wire [31:0] rdata_reg_rd_data;
wire [31:0] wdata_reg_rd_data;
wire [31:0] control_reg_rd_data;

avalon_mm_bridge_avalon_slave_0_rdata_reg rdata_reg
(
    .clk(clk),
    .reset_n(reset_n),
    .wr_data(avs_writedata),
    .wr_en(avs_write),
    .rd_en(avs_read),
    .rd_data(rdata_reg_rd_data)
);

avalon_mm_bridge_avalon_slave_0_wdata_reg wdata_reg
(
    .clk(clk),
    .reset_n(reset_n),
    .wr_data(avs_writedata),
    .wr_en(avs_write),
    .rd_data(wdata_reg_rd_data)
);

avalon_mm_bridge_avalon_slave_0_control_reg control_reg
(
    .clk(clk),
    .reset_n(reset_n),
    .wr_data(avs_writedata),
    .wr_en(avs_write),
    .rd_data(control_reg_rd_data)
);

assign avs_readdata = rdata_reg_rd_data;
assign avs_waitrequest = avm_waitrequest;
assign avs_byteenable = avm_byteenable;
assign avs_readdatavalid = avm_readdatavalid;
assign avs_writeresponsevalid = avm_writeresponse[1];
assign avs_writeresponse = avm_writeresponse[0:0];

assign avm_address = avs_address;
assign avm_writedata = wdata_reg_rd_data;
assign avm_write = avs_write;
assign avm_read = avs_read;
assign avm_readdatavalid = avm_readdatavalid;
assign avm_writeresponse = avm_writeresponse;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #1