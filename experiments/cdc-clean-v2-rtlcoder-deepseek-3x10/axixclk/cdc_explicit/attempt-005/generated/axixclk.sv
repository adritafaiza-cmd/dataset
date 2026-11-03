The complete Verilog code for the AXI4 clock-domain bridge is as follows:

```
module axixclk #(
		parameter integer C_S_AXI_ID_WIDTH	= 2,
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6,
		parameter [0:0]	OPT_WRITE_ONLY = 1'b0,
		parameter [0:0]	OPT_READ_ONLY = 1'b0,
		parameter	XCLOCK_FFS = 2,
		parameter	LGFIFO = 5
	) (
		input	wire				S_AXI_ACLK,
		input	wire				S_AXI_ARESETN,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_AWID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_AWADDR,
		input	wire [7 : 0]			S_AXI_AWLEN,
		input	wire [2 : 0]			S_AXI_AWSIZE,
		input	wire [1 : 0]			S_AXI_AWBURST,
		input	wire				S_AXI_AWLOCK,
		input	wire [3 : 0]			S_AXI_AWCACHE,
		input	wire [2 : 0]			S_AXI_AWPROT,
		input	wire [3 : 0]			S_AXI_AWQOS,
		input	wire				S_AXI_AWVALID,
		output	wire				S_AXI_AWREADY,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_WDATA,
		input	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input	wire				S_AXI_WLAST,
		input	wire				S_AXI_WVALID,
		output	wire				S_AXI_WREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_BID,
		output	wire [1 : 0]			S_AXI_BRESP,
		output	wire				S_AXI_BVALID,
		input	wire				S_AXI_BREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_ARID,
		input	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR,
		input	wire [7 : 0]			S_AXI_ARLEN,
		input	wire [2 : 0]			S_AXI_ARSIZE,
		input	wire [1 : 0]			S_AXI_ARBURST,
		input	wire				S_AXI_ARLOCK,
		input	wire [3 : 0]			S_AXI_ARCACHE,
		input	wire [2 : 0]			S_AXI_ARPROT,
		input	wire [3 : 0]			S_AXI_ARQOS,
		input	wire				S_AXI_ARVALID,
		output	wire				S_AXI_ARREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	S_AXI_RID,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA,
		output	wire [1 : 0]			S_AXI_RRESP,
		output	wire				S_AXI_RLAST,
		output	wire				S_AXI_RVALID,
		input	wire				S_AXI_RREADY,
		input	wire				M_AXI_ACLK,
		output	wire				M_AXI_ARESETN,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR,
		output	wire [7 : 0]			M_AXI_AWLEN,
		output	wire [2 : 0]			M_AXI_AWSIZE,
		output	wire [1 : 0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire [3 : 0]			M_AXI_AWCACHE,
		output	wire [2 : 0]			M_AXI_AWPROT,
		output	wire [3 : 0]			M_AXI_AWQOS,
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA,
		output	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
		output	wire				M_AXI_WLAST,
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_BID,
		input	wire [1 : 0]			M_AXI_BRESP,
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		output	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID,
		output	wire [C_S_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR,
		output	wire [7 : 0]			M_AXI_ARLEN,
		output	wire [2 : 0]			M_AXI_ARSIZE,
		output	wire [1 : 0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire [3 : 0]			M_AXI_ARCACHE,
		output	wire [2 : 0]			M_AXI_ARPROT,
		output	wire [3 : 0]			M_AXI_ARQOS,
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		input	wire [C_S_AXI_ID_WIDTH-1 : 0]	M_AXI_RID,
		input	wire [C_S_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA,
		input	wire [1 : 0]			M_AXI_RRESP,
		input	wire				M_AXI_RLAST,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY
	);

	reg [C_S_AXI_ID_WIDTH-1:0] awid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg;
	reg [7:0] awlen_reg;
	reg [2:0] awsize_reg;
	reg [1:0] awburst_reg;
	reg awlock_reg;
	reg [3:0] awcache_reg;
	reg [2:0] awprot_reg;
	reg [3:0] awqos_reg;
	reg awvalid_reg;
	reg wlast_reg;
	reg wvalid_reg;
	reg bready_reg;
	reg [C_S_AXI_ID_WIDTH-1:0] arid_reg;
	reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_reg;
	reg [7:0] arlen_reg;
	reg [2:0] arsize_reg;
	reg [1:0] arburst_reg;
	reg arlock_reg;
	reg [3:0] arcache_reg;
	reg [2:0] arprot_reg;
	reg [3:0] arqos_reg;
	reg arvalid_reg;
	reg rready_reg;

	always @(posedge S_AXI_ACLK) begin
		if (!S_AXI_ARESETN) begin
			awid_reg <= 0;
			awaddr_reg <= 0;
			awlen_reg <= 0;
			awsize_reg <= 0;
			awburst_reg <= 0;
			awlock_reg <= 0;
			awcache_reg <= 0;
			awprot_reg <= 0;
			awqos_reg <= 0;
			awvalid_reg <= 0;
			wlast_reg <= 0;
			wvalid_reg <= 0;
			bready_reg <= 0;
			arid_reg <= 0;
			araddr_reg <= 0;
			arlen_reg <= 0;
			arsize_reg <= 0;
			arburst_reg <= 0;
			arlock_reg <= 0;
			arcache_reg <= 0;
			arprot_reg <= 0;
			arqos_reg <= 0;
			arvalid_reg <= 0;
			rready_reg <= 0;
		end else begin
			awid_reg <= S_AXI_AWID;
			awaddr_reg <= S_AXI_AWADDR;
			awlen_reg <= S_AXI_AWLEN;
			awsize_reg <= S_AXI_AWSIZE;
			awburst_reg <= S_AXI_AWBURST;
			awlock_reg <= S_AXI_AWLOCK;
			awcache_reg <= S_AXI_AWCACHE;
			awprot_reg <= S_AXI_AWPROT;
			awqos_reg <= S_AXI_AWQOS;
			awvalid_reg <= S_AXI_AWVALID;
			wlast_reg <= S_AXI_WLAST;
			wvalid_reg <= S_AXI_WVALID;
			bready_reg <= S_AXI_BREADY;
			arid_reg <= S_AXI_ARID;
			araddr_reg <= S_AXI_ARADDR;
			arlen_reg <= S_AXI_ARLEN;
			arsize_reg <= S_AXI_ARSIZE;
			arburst_reg <= S_AXI_ARBURST;
			arlock_reg <= S_AXI_ARLOCK;
			arcache_reg <= S_AXI_ARCACHE;
			arprot_reg <= S_AXI_ARPROT;
			arqos_reg <= S_AXI_ARQOS;
			arvalid_reg <= S_AXI_ARVALID;
			rready_reg <= S_AXI_RREADY;
		end
	end

	assign S_AXI_AWREADY = M_AXI_AWREADY;
	assign S_AXI_WREADY = M_AXI_WREADY;
	assign S_AXI_BID = M_AXI_BID;
	assign S_AXI_BRESP = M_AXI_BRESP;
	assign S_AXI_BVALID = M_AXI_BVALID;
	assign S_AXI_ARREADY = M_AXI_ARREADY;
	assign S_AXI_RID = M_AXI_RID;
	assign S_AXI_RDATA = M_AXI_RDATA;
	assign S_AXI_RRESP = M_AXI_RRESP;
	assign S_AXI_RLAST = M_AXI_RLAST;
	assign S_AXI_RVALID = M_AXI_RVALID;

	assign M_AXI_ARESETN = S_AXI_ARESETN;
	assign M_AXI_AWID = awid_reg;
	assign M_AXI_AWADDR = awaddr_reg;
	assign M_AXI_AWLEN = awlen_reg;
	assign M_AXI_AWSIZE = awsize_reg;
	assign M_AXI_AWBURST = awburst_reg;
	assign M_AXI_AWLOCK = awlock_reg;
	assign M_AXI_AWCACHE = awcache_reg;
	assign M_AXI_AWPROT = awprot_reg;
	assign M_AXI_AWQOS = awqos_reg;
	assign M_AXI_AWVALID = awvalid_reg;
	assign M_AXI_WDATA = S_AXI_WDATA;
	assign M_AXI_WSTRB = S_AXI_WSTRB;
	assign M_AXI_WLAST = wlast_reg;
	assign M_AXI_WVALID = wvalid_reg;
	assign M_AXI_BREADY = bready_reg;
	assign M_AXI_ARID = arid_reg;
	assign M_AXI_ARADDR = araddr_reg;
	assign M_AXI_ARLEN = arlen_reg;
	assign M_AXI_ARSIZE = arsize_reg;
	assign M_AXI_ARBURST = arburst_reg;
	assign M_AXI_ARLOCK = arlock_reg;
	assign M_AXI_ARCACHE = arcache_reg;
	assign M_AXI_ARPROT = arprot_reg;
	assign M_AXI_ARQOS = arqos_reg;
	assign M_AXI_ARVALID = arvalid_reg;
	assign M_AXI_RREADY = rready_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
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
    #10 in = 8'h10;
    #10 in = 8'h11;
    #10 in = 8'h12;
    #10 in = 8'h13;
    #10 in = 8'h14;
    #10 in = 8'h15;
    #10 in = 8'h16;
    #10 in = 8'h17;
    #10 in = 8'h18;
    #10 in = 8'h19;
    #10 in = 8'h1a;
    #10 in = 8'h1b;
    #10 in = 8'h1c;
    #10 in = 8'h1d;
    #10 in = 8'h1e;
    #10 in = 8'h1f;
    #10 in = 8'h20;
    #10 in = 8'h21;
    #10 in = 8'h22;
    #10 in = 8'h23;
    #10 in = 8'h24;
    #10 in = 8'h25;
    #10 in = 8'h26;
    #10 in = 8'h27;
    #10 in = 8'h28;
    #10 in = 8'h29;
    #10 in = 8'h2a;
    #10 in = 8'h2b;
    #10 in = 8'h2c;
    #10 in = 8'h2d;
    #10 in = 8'h2e;
    #10 in = 8'h2f;
    #10 in = 8'h30;
    #10 in = 8'h31;
    #10 in = 8'h32;
    #10 in = 8'h33;
    #10 in = 8'h34;
    #10 in = 8'h35;
    #10 in = 8'h36;
    #10 in = 8'h37;
    #10 in = 8'h38;
    #10 in = 8'h39;
    #10 in = 8'h3a;
    #10 in = 8'h3b;
    #10 in = 8'h3c;
    #10 in = 8'h3d;
    #10 in = 8'h3e;
    #10 in = 8'h3f;
    #10 in = 8'h40;
    #10 in = 8'h41;
    #10 in = 8'h42;
    #10 in = 8'h43;
    #10 in = 8'h44;
    #10 in = 8'h45;
    #10 in = 8'h46;
    #10 in = 8'h47;
    #10 in = 8'h48;
    #10 in = 8'h49;
    #10 in = 8'h4a;
    #10 in = 8'h4b;
    #10 in = 8'h4c;
    #10 in = 8'h4d;
    #10 in = 8'h4e;
    #10 in = 8'h4f;
    #10 in = 8'h50;
    #10 in = 8'h51;
    #10 in = 8'h52;
    #10 in = 8'h53;
    #10 in = 8'h54;
    #10 in = 8'h55;
    #10 in = 8'h56;
    #10 in = 8'h57;
    #10 in = 8'h58;
    #10 in = 8'h59;
    #10 in = 8'h5a;
    #10 in = 8'h5b;
    #10 in = 8'h5c;
    #10 in = 8'h5d;
    #10 in = 8'h5e;
    #10 in = 8'h5f;
    #10 in = 8'h60;
    #10 in = 8'h61;
    #10 in = 8'h62;
    #10 in = 8'h63;
    #10 in = 8'h64;
    #10 in = 8'h65;
    #10 in = 8'h66;
    #10 in = 8'h67;
    #10 in = 8'h68;
    #10 in = 8'h69;
    #10 in = 8'h6a;
    #10 in = 8'h6b;
    #10 in = 8'h6c;
    #10 in = 8'h6d;
    #10 in = 8'h6e;
    #10 in = 8'h6f;
    #10 in = 8'h70;
    #10 in = 8'h71;
    #10 in = 8'h72;
    #10 in = 8'h73;
    #10 in = 8'h74;
    #10 in = 8'h75;
    #10 in = 8'h76;
    #10 in = 8'h77;
    #10 in = 8'h78;
    #10 in = 8'h79;
    #10 in = 8'h7a;
    #10 in = 8'h7b;
    #10 in = 8'h7c;
    #10 in = 8'h7d;
    #10 in = 8'h7e;
    #10 in = 8'h7f;
    #10 in = 8'h80;
    #10 in = 8'h81;
    #10 in = 8'h82;
    #10 in = 8'h83;
    #10 in = 8'h84;
    #10 in = 8'h85;
    #10 in = 8'h86;
    #10 in = 8'h87;
    #10 in = 8'h88;
    #10 in = 8'h89;
    #10 in = 8'h8a;
    #10 in = 8'h8b;
    #10 in = 8'h8c;
    #10 in = 8'h8d;
    #10 in = 8'h8e;
    #10 in = 8'h8f;
    #10 in = 8'h90;
    #10 in = 8'h91;
    #10 in = 8'h92;
    #10 in = 8'h93;
    #10 in = 8'h94;
    #10 in = 8'h95;
    #10 in = 8'h96;
    #10 in = 8'h97;
    #10 in = 8'h98;
    #10 in = 8'h99;
    #10 in = 8'h9a;
    #10 in = 8'h9b;
    #10 in = 8'h9c;
    #10 in = 8'h9d;
    #10 in = 8'h9e;
    #10 in = 8'h9f;
    #10 in = 8'ha0;
    #10 in = 8'ha1;
    #10 in = 8'ha2;
    #10 in = 8'ha3;
    #10 in = 8'ha4;
    #10 in = 8'ha5;
    #10 in = 8'ha6;
    #10 in = 8'ha7;
    #10 in = 8'ha8;
    #10 in = 8'ha9;
    #10 in = 8'haa;
    #10 in = 8'hab;
    #10 in = 8'hac;
    #10 in = 8'had;
    #10 in = 8'hae;
    #10 in = 8'haf;
    #10 in = 8'hb0;
    #10 in = 8'hb1;
    #10 in = 8'hb2;
    #10 in = 8'hb3;
    #10 in = 8'hb4;
    #10 in = 8'hb5;
    #10 in = 8'hb6;
    #10 in = 8'hb7;
    #10 in = 8'hb8;
    #10 in = 8'hb9;
    #10 in = 8'hba;
    #10 in = 8'hbb;
    #10 in = 8'hbc;
    #10 in = 8'hbd;
    #10 in = 8'hbe;
    #10 in = 8'hbf;
    #10 in = 8'hc0;
    #10 in = 8'hc1;
    #10 in = 8'hc2;
    #10 in = 8'hc3;
    #10 in = 8'hc4;
    #10 in = 8'hc5;
    #10 in = 8'hc6;
    #10 in = 8'hc7;
    #10 in = 8'hc8;
    #10 in = 8'hc9;
    #10 in = 8'hca;
    #10 in = 8'hcb;
    #10 in = 8'hcc;
    #10 in = 8'hcd;
    #10 in = 8'hce;
    #10 in = 8'hcf;
    #10 in = 8'hd0;
    #10 in = 8'hd1;
    #10 in = 8'hd2;
    #10 in = 8'hd3;
    #10 in = 8'hd4;
    #10 in = 8'hd5;
    #10 in = 8'hd6;
    #10 in = 8'hd7;
    #10 in = 8'hd8;
    #10 in = 8'hd9;
    #10 in = 8'hda;
    #10 in = 8'hdb;
    #10 in = 8'hdc;
    #10 in = 8'hdd;
    #10 in = 8'hde;
    #10 in = 8'hdf;
    #10 in = 8'he0;
    #10 in = 8'he1;
    #10 in = 8'he2;
    #10 in = 8'he3;
    #10 in = 8'he4;
    #10 in = 8'he5;
    #10 in = 8'he6;
    #10 in = 8'he7;
    #10 in = 8'he8;
    #10 in = 8'he9;
    #10 in = 8'hea;
    #10 in = 8'heb;
    #10 in = 8'hec;
    #10 in = 8'hed;
    #10 in = 8'hee;
    #10 in = 8'hef;
    #10 in = 8'hf0;
    #10 in = 8'hf1;
    #10 in = 8'hf2;
    #10 in = 8'hf3;
    #10 in = 8'hf4;
    #10 in = 8'hf5;
    #10 in = 8'hf6;
    #10 in = 8'hf7;
    #10 in = 8'hf8;
    #10 in = 8'hf9;
    #10 in = 8'hfa;
    #10 in = 8'hfb;
    #10 in = 8'hfc;
    #10 in = 8'hfd;
    #10 in = 8'hfe;
    #10 in = 8'hff;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
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
    #10 in = 8'