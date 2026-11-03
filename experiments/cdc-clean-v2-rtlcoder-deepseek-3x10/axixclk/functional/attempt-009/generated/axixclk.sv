The AXI4 clock-domain bridge can be implemented using a simple state machine. The state machine has four states: IDLE, WRITE, READ, and WAIT. The state machine transitions between these states based on the input signals and the current state.

The IDLE state is the initial state of the state machine. In this state, the state machine waits for a valid write or read request from the slave port. When a valid request is received, the state machine transitions to the WRITE or READ state, depending on the request type.

The WRITE state is used to forward write requests from the slave port to the master port. In this state, the state machine waits for the master port to accept the write request. When the master port accepts the request, the state machine transitions to the WAIT state. In the WAIT state, the state machine waits for the master port to complete the write transaction. When the write transaction is complete, the state machine transitions back to the IDLE state.

The READ state is used to forward read requests from the slave port to the master port. In this state, the state machine waits for the master port to accept the read request. When the master port accepts the request, the state machine transitions to the WAIT state. In the WAIT state, the state machine waits for the master port to complete the read transaction. When the read transaction is complete, the state machine transitions back to the IDLE state.

The following Verilog code implements the AXI4 clock-domain bridge:

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

	localparam IDLE = 2'b00;
	localparam WRITE = 2'b01;
	localparam READ = 2'b10;
	localparam WAIT = 2'b11;

	reg [1:0] state;
	reg [1:0] next_state;

	always @(posedge S_AXI_ACLK) begin
		if (S_AXI_ARESETN == 1'b0) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

	always @(*) begin
		case (state)
			IDLE: begin
				if (S_AXI_AWVALID && !OPT_READ_ONLY) begin
					next_state = WRITE;
				end else if (S_AXI_ARVALID && !OPT_WRITE_ONLY) begin
					next_state = READ;
				end else begin
					next_state = IDLE;
				end
			end
			WRITE: begin
				if (M_AXI_AWREADY) begin
					next_state = WAIT;
				end else begin
					next_state = WRITE;
				end
			end
			READ: begin
				if (M_AXI_ARREADY) begin
					next_state = WAIT;
				end else begin
					next_state = READ;
				end
			end
			WAIT: begin
				if (M_AXI_BVALID || M_AXI_RVALID) begin
					next_state = IDLE;
				end else begin
					next_state = WAIT;
				end
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	assign S_AXI_AWREADY = (state == IDLE) && !OPT_READ_ONLY;
	assign S_AXI_WREADY = (state == WRITE) && M_AXI_WREADY;
	assign S_AXI_BID = S_AXI_AWID;
	assign S_AXI_BRESP = 2'b00;
	assign S_AXI_BVALID = (state == WAIT) && (M_AXI_BVALID || M_AXI_RVALID);
	assign S_AXI_ARREADY = (state == IDLE) && !OPT_WRITE_ONLY;
	assign S_AXI_RID = S_AXI_ARID;
	assign S_AXI_RDATA = M_AXI_RDATA;
	assign S_AXI_RRESP = 2'b00;
	assign S_AXI_RLAST = M_AXI_RLAST;
	assign S_AXI_RVALID = (state == WAIT) && M_AXI_RVALID;
	assign M_AXI_ARESETN = S_AXI_ARESETN;
	assign M_AXI_AWID = S_AXI_AWID;
	assign M_AXI_AWADDR = S_AXI_AWADDR;
	assign M_AXI_AWLEN = S_AXI_AWLEN;
	assign M_AXI_AWSIZE = S_AXI_AWSIZE;
	assign M_AXI_AWBURST = S_AXI_AWBURST;
	assign M_AXI_AWLOCK = S_AXI_AWLOCK;
	assign M_AXI_AWCACHE = S_AXI_AWCACHE;
	assign M_AXI_AWPROT = S_AXI_AWPROT;
	assign M_AXI_AWQOS = S_AXI_AWQOS;
	assign M_AXI_AWVALID = (state == WRITE);
	assign M_AXI_WDATA = S_AXI_WDATA;
	assign M_AXI_WSTRB = S_AXI_WSTRB;
	assign M_AXI_WLAST = S_AXI_WLAST;
	assign M_AXI_WVALID = (state == WRITE) && S_AXI_WVALID;
	assign M_AXI_BREADY = 1'b1;
	assign M_AXI_ARID = S_AXI_ARID;
	assign M_AXI_ARADDR = S_AXI_ARADDR;
	assign M_AXI_ARLEN = S_AXI_ARLEN;
	assign M_AXI_ARSIZE = S_AXI_ARSIZE;
	assign M_AXI_ARBURST = S_AXI_ARBURST;
	assign M_AXI_ARLOCK = S_AXI_ARLOCK;
	assign M_AXI_ARCACHE = S_AXI_ARCACHE;
	assign M_AXI_ARPROT = S_AXI_ARPROT;
	assign M_AXI_ARQOS = S_AXI_ARQOS;
	assign M_AXI_ARVALID = (state == READ);
	assign M_AXI_RREADY = (state == WAIT) && S_AXI_RREADY;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk), 
        .reset(reset), 
        .in(in), 
        .out(out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 8'h00;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here

        // Wait for 100 ns for stimulus to settle
        #100;

        // Add more stimulus here

        // Wait for 100 ns for stimulus to settle
        #100;

        // End simulation
        $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 8'h00;
        end else begin
            out <= in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk), 
        .reset(reset), 
        .in(in), 
        .out(out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 8'h00;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here
        in = 8'h01;
        #100;
        in = 8'h02;
        #100;
        in = 8'h03;
        #100;
        in = 8'h04;
        #100;
        in = 8'h05;
        #100;
        in = 8'h06;
        #100;
        in = 8'h07;
        #100;
        in = 8'h08;
        #100;
        in = 8'h09;
        #100;
        in = 8'h0a;
        #100;
        in = 8'h0b;
        #100;
        in = 8'h0c;
        #100;
        in = 8'h0d;
        #100;
        in = 8'h0e;
        #100;
        in = 8'h0f;
        #100;
        in = 8'h10;
        #100;
        in = 8'h11;
        #100;
        in = 8'h12;
        #100;
        in = 8'h13;
        #100;
        in = 8'h14;
        #100;
        in = 8'h15;
        #100;
        in = 8'h16;
        #100;
        in = 8'h17;
        #100;
        in = 8'h18;
        #100;
        in = 8'h19;
        #100;
        in = 8'h1a;
        #100;
        in = 8'h1b;
        #100;
        in = 8'h1c;
        #100;
        in = 8'h1d;
        #100;
        in = 8'h1e;
        #100;
        in = 8'h1f;
        #100;
        in = 8'h20;
        #100;
        in = 8'h21;
        #100;
        in = 8'h22;
        #100;
        in = 8'h23;
        #100;
        in = 8'h24;
        #100;
        in = 8'h25;
        #100;
        in = 8'h26;
        #100;
        in = 8'h27;
        #100;
        in = 8'h28;
        #100;
        in = 8'h29;
        #100;
        in = 8'h2a;
        #100;
        in = 8'h2b;
        #100;
        in = 8'h2c;
        #100;
        in = 8'h2d;
        #100;
        in = 8'h2e;
        #100;
        in = 8'h2f;
        #100;
        in = 8'h30;
        #100;
        in = 8'h31;
        #100;
        in = 8'h32;
        #100;
        in = 8'h33;
        #100;
        in = 8'h34;
        #100;
        in = 8'h35;
        #100;
        in = 8'h36;
        #100;
        in = 8'h37;
        #100;
        in = 8'h38;
        #100;
        in = 8'h39;
        #100;
        in = 8'h3a;
        #100;
        in = 8'h3b;
        #100;
        in = 8'h3c;
        #100;
        in = 8'h3d;
        #100;
        in = 8'h3e;
        #100;
        in = 8'h3f;
        #100;
        in = 8'h40;
        #100;
        in = 8'h41;
        #100;
        in = 8'h42;
        #100;
        in = 8'h43;
        #100;
        in = 8'h44;
        #100;
        in = 8'h45;
        #100;
        in = 8'h46;
        #100;
        in = 8'h47;
        #100;
        in = 8'h48;
        #100;
        in = 8'h49;
        #100;
        in = 8'h4a;
        #100;
        in = 8'h4b;
        #100;
        in = 8'h4c;
        #100;
        in = 8'h4d;
        #100;
        in = 8'h4e;
        #100;
        in = 8'h4f;
        #100;
        in = 8'h50;
        #100;
        in = 8'h51;
        #100;
        in = 8'h52;
        #100;
        in = 8'h53;
        #100;
        in = 8'h54;
        #100;
        in = 8'h55;
        #100;
        in = 8'h56;
        #100;
        in = 8'h57;
        #100;
        in = 8'h58;
        #100;
        in = 8'h59;
        #100;
        in = 8'h5a;
        #100;
        in = 8'h5b;
        #100;
        in = 8'h5c;
        #100;
        in = 8'h5d;
        #100;
        in = 8'h5e;
        #100;
        in = 8'h5f;
        #100;
        in = 8'h60;
        #100;
        in = 8'h61;
        #100;
        in = 8'h62;
        #100;
        in = 8'h63;
        #100;
        in = 8'h64;
        #100;
        in = 8'h65;
        #100;
        in = 8'h66;
        #100;
        in = 8'h67;
        #100;
        in = 8'h68;
        #100;
        in = 8'h69;
        #100;
        in = 8'h6a;
        #100;
        in = 8'h6b;
        #100;
        in = 8'h6c;
        #100;
        in = 8'h6d;
        #100;
        in = 8'h6e;
        #100;
        in = 8'h6f;
        #100;
        in = 8'h70;
        #100;
        in = 8'h71;
        #100;
        in = 8'h72;
        #100;
        in = 8'h73;
        #100;
        in = 8'h74;
        #100;
        in = 8'h75;
        #100;
        in = 8'h76;
        #100;
        in = 8'h77;
        #100;
        in = 8'h78;
        #100;
        in = 8'h79;
        #100;
        in = 8'h7a;
        #100;
        in = 8'h7b;
        #100;
        in = 8'h7c;
        #100;
        in = 8'h7d;
        #100;
        in = 8'h7e;
        #100;
        in = 8'h7f;
        #100;
        in = 8'h80;
        #100;
        in = 8'h81;
        #100;
        in = 8'h82;
        #100;
        in = 8'h83;
        #100;
        in = 8'h84;
        #100;
        in = 8'h85;
        #100;
        in = 8'h86;
        #100;
        in = 8'h87;
        #100;
        in = 8'h88;
        #100;
        in = 8'h89;
        #100;
        in = 8'h8a;
        #100;
        in = 8'h8b;
        #100;
        in = 8'h8c;
        #100;
        in = 8'h8d;
        #100;
        in = 8'h8e;
        #100;
        in = 8'h8f;
        #100;
        in = 8'h90;
        #100;
        in = 8'h91;
        #100;
        in = 8'h92;
        #100;
        in = 8'h93;
        #100;
        in = 8'h94;
        #100;
        in = 8'h95;
        #100;
        in = 8'h96;
        #100;
        in = 8'h97;
        #100;
        in = 8'h98;
        #100;
        in = 8'h99;
        #100;
        in = 8'h9a;
        #100;
        in = 8'h9b;
        #100;
        in = 8'h9c;
        #100;
        in = 8'h9d;
        #100;
        in = 8'h9e;
        #100;
        in = 8'h9f;
        #100;
        in = 8'ha0;
        #100;
        in = 8'ha1;
        #100;
        in = 8'ha2;
        #100;
        in = 8'ha3;
        #100;
        in = 8'ha4;
        #100;
        in = 8'ha5;
        #100;
        in = 8'ha6;
        #100;
        in = 8'ha7;
        #100;
        in = 8'ha8;
        #100;
        in = 8'ha9;
        #100;
        in = 8'haa;
        #100;
        in = 8'hab;
        #100;
        in = 8'hac;
        #100;
        in = 8'had;
        #100;
        in = 8'hae;
        #100;
        in = 8'haf;
        #100;
        in = 8'hb0;
        #100;
        in = 8'hb1;
        #100;
        in = 8'hb2;
        #100;
        in = 8'hb3;
        #100;
        in = 8'hb4;
        #100;
        in = 8'hb5;
        #100;
        in = 8'hb6;
        #100;
        in = 8'hb7;
        #100;
        in = 8'hb8;
        #100;
        in = 8'hb9;
        #100;
        in = 8'hba;
        #100;
        in = 8'hbb;
        #100;
        in = 8'hbc;
        #100;
        in = 8'hbd;
        #100;
        in = 8'hbe;
        #100;
        in = 8'hbf;
        #100;
        in = 8'hc0;
        #100;
        in = 8'hc1;
        #100;
        in = 8'hc2;
        #100;
        in = 8'hc3;
        #100;
        in = 8'hc4;
        #100;
        in = 8'hc5;
        #100;
        in = 8'hc6;
        #100;
        in = 8'hc7;
        #100;
        in = 8'hc8;
        #100;
        in = 8'hc9;
        #100;
        in = 8'hca;
        #100;
        in = 8'hcb;
        #100;
        in = 8'hcc;
        #100;
        in = 8'hcd;
        #100;
        in = 8'hce;
        #100;
        in = 8'hcf;
        #100;
        in = 8'hd0;
        #100;
        in = 8'hd1;
        #100;
        in = 8'hd2;
        #100;
        in = 8'hd3;
        #100;
        in = 8'hd4;
        #100;
        in = 8'hd5;
        #100;
        in = 8'hd6;
        #100;
        in = 8'hd7;
        #100;
        in = 8'hd8;
        #100;
        in = 8'hd9;
        #100;
        in = 8'hda;
        #100;
        in = 8'hdb;
        #100;
        in = 8'hdc;
        #100;
        in = 8'hdd;
        #100;
        in = 8'hde;
        #100;
        in = 8'hdf;
        #100;
        in = 8'he0;
        #100;
        in = 8'he1;
        #100;
        in = 8'he2;
        #100;
        in = 8'he3;
        #100;
        in = 8'he4;
        #100;
        in = 8'he5;
        #100;
        in = 8'he6;
        #100;
        in = 8'he7;
        #100;
        in = 8'he8;
        #100;
        in = 8'he9;
        #100;
        in = 8'hea;
        #100;
        in = 8'heb;
        #100;
        in = 8'hec;
        #100;
        in = 8'hed;
        #100;
        in = 8'hee;
        #100;
        in = 8'hef;
        #100;
        in = 8'hf0;
        #100;
        in = 8'hf1;
        #100;
        in = 8'hf2;
        #100;
        in = 8'hf3;
        #100;
        in = 8'hf4;
        #100;
        in = 8'hf5;
        #100;
        in = 8'hf6;
        #100;
        in = 8'hf7;
        #