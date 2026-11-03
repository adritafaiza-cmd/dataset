Here is the complete Verilog code for the APB clock-domain bridge module:

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

	reg [DW-1:0] S_APB_PRDATA_reg;
	reg S_APB_PSLVERR_reg;
	reg [DW-1:0] M_APB_PRDATA_reg;
	reg M_APB_PSLVERR_reg;

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			S_APB_PRDATA_reg <= {DW{1'b0}};
			S_APB_PSLVERR_reg <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				S_APB_PREADY <= 1'b0;
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				M_APB_PADDR <= S_APB_PADDR;
				M_APB_PWRITE <= S_APB_PWRITE;
				M_APB_PWDATA <= S_APB_PWDATA;
				M_APB_PWSTRB <= S_APB_PWSTRB;
				M_APB_PPROT <= S_APB_PPROT;
			end else if (M_APB_PREADY) begin
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA_reg <= M_APB_PRDATA_reg;
				S_APB_PSLVERR_reg <= M_APB_PSLVERR_reg;
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
			M_APB_PRDATA_reg <= {DW{1'b0}};
			M_APB_PSLVERR_reg <= 1'b0;
		end else begin
			if (M_APB_PSEL && M_APB_PENABLE) begin
				M_APB_PRDATA_reg <= M_APB_PRDATA;
				M_APB_PSLVERR_reg <= M_APB_PSLVERR;
			end
			M_PRESETn <= 1'b1;
		end
	end

	assign S_APB_PRDATA = OPT_REGISTERED ? S_APB_PRDATA_reg : M_APB_PRDATA;
	assign S_APB_PSLVERR = OPT_REGISTERED ? S_APB_PSLVERR_reg : M_APB_PSLVERR;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg rst_n;
    reg [7:0] data_in;
    reg data_in_valid;

    // Outputs
    wire [7:0] data_out;
    wire data_out_valid;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        data_in_valid = 0;
        #20 data_in = 8'h01;
        data_in_valid = 1;
        #20 data_in = 8'h02;
        data_in_valid = 1;
        #20 data_in = 8'h03;
        data_in_valid = 1;
        #20 data_in = 8'h04;
        data_in_valid = 1;
        #20 data_in = 8'h05;
        data_in_valid = 1;
        #20 data_in = 8'h06;
        data_in_valid = 1;
        #20 data_in = 8'h07;
        data_in_valid = 1;
        #20 data_in = 8'h08;
        data_in_valid = 1;
        #20 data_in = 8'h09;
        data_in_valid = 1;
        #20 data_in = 8'h0a;
        data_in_valid = 1;
        #20 data_in = 8'h0b;
        data_in_valid = 1;
        #20 data_in = 8'h0c;
        data_in_valid = 1;
        #20 data_in = 8'h0d;
        data_in_valid = 1;
        #20 data_in = 8'h0e;
        data_in_valid = 1;
        #20 data_in = 8'h0f;
        data_in_valid = 1;
        #20 data_in = 8'h10;
        data_in_valid = 1;
        #20 data_in = 8'h11;
        data_in_valid = 1;
        #20 data_in = 8'h12;
        data_in_valid = 1;
        #20 data_in = 8'h13;
        data_in_valid = 1;
        #20 data_in = 8'h14;
        data_in_valid = 1;
        #20 data_in = 8'h15;
        data_in_valid = 1;
        #20 data_in = 8'h16;
        data_in_valid = 1;
        #20 data_in = 8'h17;
        data_in_valid = 1;
        #20 data_in = 8'h18;
        data_in_valid = 1;
        #20 data_in = 8'h19;
        data_in_valid = 1;
        #20 data_in = 8'h1a;
        data_in_valid = 1;
        #20 data_in = 8'h1b;
        data_in_valid = 1;
        #20 data_in = 8'h1c;
        data_in_valid = 1;
        #20 data_in = 8'h1d;
        data_in_valid = 1;
        #20 data_in = 8'h1e;
        data_in_valid = 1;
        #20 data_in = 8'h1f;
        data_in_valid = 1;
        #20 data_in = 8'h20;
        data_in_valid = 1;
        #20 data_in = 8'h21;
        data_in_valid = 1;
        #20 data_in = 8'h22;
        data_in_valid = 1;
        #20 data_in = 8'h23;
        data_in_valid = 1;
        #20 data_in = 8'h24;
        data_in_valid = 1;
        #20 data_in = 8'h25;
        data_in_valid = 1;
        #20 data_in = 8'h26;
        data_in_valid = 1;
        #20 data_in = 8'h27;
        data_in_valid = 1;
        #20 data_in = 8'h28;
        data_in_valid = 1;
        #20 data_in = 8'h29;
        data_in_valid = 1;
        #20 data_in = 8'h2a;
        data_in_valid = 1;
        #20 data_in = 8'h2b;
        data_in_valid = 1;
        #20 data_in = 8'h2c;
        data_in_valid = 1;
        #20 data_in = 8'h2d;
        data_in_valid = 1;
        #20 data_in = 8'h2e;
        data_in_valid = 1;
        #20 data_in = 8'h2f;
        data_in_valid = 1;
        #20 data_in = 8'h30;
        data_in_valid = 1;
        #20 data_in = 8'h31;
        data_in_valid = 1;
        #20 data_in = 8'h32;
        data_in_valid = 1;
        #20 data_in = 8'h33;
        data_in_valid = 1;
        #20 data_in = 8'h34;
        data_in_valid = 1;
        #20 data_in = 8'h35;
        data_in_valid = 1;
        #20 data_in = 8'h36;
        data_in_valid = 1;
        #20 data_in = 8'h37;
        data_in_valid = 1;
        #20 data_in = 8'h38;
        data_in_valid = 1;
        #20 data_in = 8'h39;
        data_in_valid = 1;
        #20 data_in = 8'h3a;
        data_in_valid = 1;
        #20 data_in = 8'h3b;
        data_in_valid = 1;
        #20 data_in = 8'h3c;
        data_in_valid = 1;
        #20 data_in = 8'h3d;
        data_in_valid = 1;
        #20 data_in = 8'h3e;
        data_in_valid = 1;
        #20 data_in = 8'h3f;
        data_in_valid = 1;
        #20 data_in = 8'h40;
        data_in_valid = 1;
        #20 data_in = 8'h41;
        data_in_valid = 1;
        #20 data_in = 8'h42;
        data_in_valid = 1;
        #20 data_in = 8'h43;
        data_in_valid = 1;
        #20 data_in = 8'h44;
        data_in_valid = 1;
        #20 data_in = 8'h45;
        data_in_valid = 1;
        #20 data_in = 8'h46;
        data_in_valid = 1;
        #20 data_in = 8'h47;
        data_in_valid = 1;
        #20 data_in = 8'h48;
        data_in_valid = 1;
        #20 data_in = 8'h49;
        data_in_valid = 1;
        #20 data_in = 8'h4a;
        data_in_valid = 1;
        #20 data_in = 8'h4b;
        data_in_valid = 1;
        #20 data_in = 8'h4c;
        data_in_valid = 1;
        #20 data_in = 8'h4d;
        data_in_valid = 1;
        #20 data_in = 8'h4e;
        data_in_valid = 1;
        #20 data_in = 8'h4f;
        data_in_valid = 1;
        #20 data_in = 8'h50;
        data_in_valid = 1;
        #20 data_in = 8'h51;
        data_in_valid = 1;
        #20 data_in = 8'h52;
        data_in_valid = 1;
        #20 data_in = 8'h53;
        data_in_valid = 1;
        #20 data_in = 8'h54;
        data_in_valid = 1;
        #20 data_in = 8'h55;
        data_in_valid = 1;
        #20 data_in = 8'h56;
        data_in_valid = 1;
        #20 data_in = 8'h57;
        data_in_valid = 1;
        #20 data_in = 8'h58;
        data_in_valid = 1;
        #20 data_in = 8'h59;
        data_in_valid = 1;
        #20 data_in = 8'h5a;
        data_in_valid = 1;
        #20 data_in = 8'h5b;
        data_in_valid = 1;
        #20 data_in = 8'h5c;
        data_in_valid = 1;
        #20 data_in = 8'h5d;
        data_in_valid = 1;
        #20 data_in = 8'h5e;
        data_in_valid = 1;
        #20 data_in = 8'h5f;
        data_in_valid = 1;
        #20 data_in = 8'h60;
        data_in_valid = 1;
        #20 data_in = 8'h61;
        data_in_valid = 1;
        #20 data_in = 8'h62;
        data_in_valid = 1;
        #20 data_in = 8'h63;
        data_in_valid = 1;
        #20 data_in = 8'h64;
        data_in_valid = 1;
        #20 data_in = 8'h65;
        data_in_valid = 1;
        #20 data_in = 8'h66;
        data_in_valid = 1;
        #20 data_in = 8'h67;
        data_in_valid = 1;
        #20 data_in = 8'h68;
        data_in_valid = 1;
        #20 data_in = 8'h69;
        data_in_valid = 1;
        #20 data_in = 8'h6a;
        data_in_valid = 1;
        #20 data_in = 8'h6b;
        data_in_valid = 1;
        #20 data_in = 8'h6c;
        data_in_valid = 1;
        #20 data_in = 8'h6d;
        data_in_valid = 1;
        #20 data_in = 8'h6e;
        data_in_valid = 1;
        #20 data_in = 8'h6f;
        data_in_valid = 1;
        #20 data_in = 8'h70;
        data_in_valid = 1;
        #20 data_in = 8'h71;
        data_in_valid = 1;
        #20 data_in = 8'h72;
        data_in_valid = 1;
        #20 data_in = 8'h73;
        data_in_valid = 1;
        #20 data_in = 8'h74;
        data_in_valid = 1;
        #20 data_in = 8'h75;
        data_in_valid = 1;
        #20 data_in = 8'h76;
        data_in_valid = 1;
        #20 data_in = 8'h77;
        data_in_valid = 1;
        #20 data_in = 8'h78;
        data_in_valid = 1;
        #20 data_in = 8'h79;
        data_in_valid = 1;
        #20 data_in = 8'h7a;
        data_in_valid = 1;
        #20 data_in = 8'h7b;
        data_in_valid = 1;
        #20 data_in = 8'h7c;
        data_in_valid = 1;
        #20 data_in = 8'h7d;
        data_in_valid = 1;
        #20 data_in = 8'h7e;
        data_in_valid = 1;
        #20 data_in = 8'h7f;
        data_in_valid = 1;
        #20 data_in = 8'h80;
        data_in_valid = 1;
        #20 data_in = 8'h81;
        data_in_valid = 1;
        #20 data_in = 8'h82;
        data_in_valid = 1;
        #20 data_in = 8'h83;
        data_in_valid = 1;
        #20 data_in = 8'h84;
        data_in_valid = 1;
        #20 data_in = 8'h85;
        data_in_valid = 1;
        #20 data_in = 8'h86;
        data_in_valid = 1;
        #20 data_in = 8'h87;
        data_in_valid = 1;
        #20 data_in = 8'h88;
        data_in_valid = 1;
        #20 data_in = 8'h89;
        data_in_valid = 1;
        #20 data_in = 8'h8a;
        data_in_valid = 1;
        #20 data_in = 8'h8b;
        data_in_valid = 1;
        #20 data_in = 8'h8c;
        data_in_valid = 1;
        #20 data_in = 8'h8d;
        data_in_valid = 1;
        #20 data_in = 8'h8e;
        data_in_valid = 1;
        #20 data_in = 8'h8f;
        data_in_valid = 1;
        #20 data_in = 8'h90;
        data_in_valid = 1;
        #20 data_in = 8'h91;
        data_in_valid = 1;
        #20 data_in = 8'h92;
        data_in_valid = 1;
        #20 data_in = 8'h93;
        data_in_valid = 1;
        #20 data_in = 8'h94;
        data_in_valid = 1;
        #20 data_in = 8'h95;
        data_in_valid = 1;
        #20 data_in = 8'h96;
        data_in_valid = 1;
        #20 data_in = 8'h97;
        data_in_valid = 1;
        #20 data_in = 8'h98;
        data_in_valid = 1;
        #20 data_in = 8'h99;
        data_in_valid = 1;
        #20 data_in = 8'h9a;
        data_in_valid = 1;
        #20 data_in = 8'h9b;
        data_in_valid = 1;
        #20 data_in = 8'h9c;
        data_in_valid = 1;
        #20 data_in = 8'h9d;
        data_in_valid = 1;
        #20 data_in = 8'h9e;
        data_in_valid = 1;
        #20 data_in = 8'h9f;
        data_in_valid = 1;
        #20 data_in = 8'ha0;
        data_in_valid = 1;
        #20 data_in = 8'ha1;
        data_in_valid = 1;
        #20 data_in = 8'ha2;
        data_in_valid = 1;
        #20 data_in = 8'ha3;
        data_in_valid = 1;
        #20 data_in = 8'ha4;
        data_in_valid = 1;
        #20 data_in = 8'ha5;
        data_in_valid = 1;
        #20 data_in = 8'ha6;
        data_in_valid = 1;
        #20 data_in = 8'ha7;
        data_in_valid = 1;
        #20 data_in = 8'ha8;
        data_in_valid = 1;
        #20 data_in = 8'ha9;
        data_in_valid = 1;
        #20 data_in = 8'haa;
        data_in_valid = 1;
        #20 data_in = 8'hab;
        data_in_valid = 1;
        #20 data_in = 8'hac;
        data_in_valid = 1;
        #20 data_in = 8'had;
        data_in_valid = 1;
        #20 data_in = 8'hae;
        data_in_valid = 1;
        #20 data_in = 8'haf;
        data_in_valid = 1;
        #20 data_in = 8'hb0;
        data_in_valid = 1;
        #20 data_in = 8'hb1;
        data_in_valid = 1;
        #20 data_in = 8'hb2;
        data_in_valid = 1;
        #20 data_in = 8'hb3;
        data_in_valid = 1;
        #20 data_in = 8'hb4;
        data_in_valid = 1;
        #20 data_in = 8'hb5;
        data_in_valid = 1;
        #20 data_in = 8'hb6;
        data_in_valid = 1;
        #20 data_in = 8'hb7;
        data_in_valid = 1;
        #20 data_in = 8'hb8;
        data_in_valid = 1;
        #20 data_in = 8'hb9;
        data_in_valid = 1;
        #20 data_in = 8'hba;
        data_in_valid = 1;
        #20 data_in = 8'hbb;
        data_in_valid = 1;
        #20 data_in = 8'hbc;
        data_in_valid = 1;
        #20 data_in = 8'hbd;
        data_in_valid = 1;
        #20 data_in = 8'hbe;
        data_in_valid = 1;
        #20 data_in = 8'hbf;
        data_in_valid = 1;
        #20 data_in = 8'hc0;
        data_in_valid = 1;
        #20 data_in = 8'hc1;
        data_in_valid = 1;
        #20 data_in = 8'hc2;
        data_in_valid = 1;
        #20 data_in = 8'hc3;
        data_in_valid = 1;
        #20 data_in = 8'hc4;
        data_in_valid = 1;
        #20 data_in = 8'hc5;
        data_in_valid = 1;
        #20 data_in = 8'hc6;
        data_in_valid = 1;
        #20 data_in = 8'hc7;
        data_in_valid = 1;
        #20 data_in = 8'hc8;
        data_in_valid = 1;
        #20 data_in = 8'hc9;
        data_in_valid = 1;
        #20 data_in = 8'hca;
        data_in_valid = 1;
        #20 data_in = 8'hcb;
        data_in_valid = 1;
        #20 data_in = 8'hcc;
        data_in_valid = 1;
        #20 data_in = 8'hcd;
        data_in_valid = 1;
        #20 data_in = 8'hce;
        data_in_valid = 1;
        #20 data_in = 8'hcf;
        data_in_valid = 1;
        #20 data_in = 8'hd0;
        data_in_valid = 1;
        #20 data_in = 8'hd1;
        data_in_valid = 1;
        #20 data_in = 8'hd2;
        data_in_valid = 1;
        #20 data_in = 8'hd3;
        data_in_valid = 1;
        #20 data_in = 8'hd4;
        data_in_valid = 1;
        #20 data_in = 8'hd5;
        data_in_valid = 1;
        #20 data_in = 8'hd6;
        data_in_valid = 1;
        #20 data_in = 8'hd7;
        data_in_valid = 1;
        #20 data_in = 8'hd8;
        data_in_valid = 1;
        #20 data_in = 8'hd9;
        data_in_valid = 1;
        #20 data_in = 8'hda;
        data_in_valid = 1;
        #20 data_in = 8'hdb;
        data_in_valid = 1;
        #20 data_in = 8'hdc;
        data_in_valid = 1;
        #20 data_in = 8'hdd;
        data_in_valid = 1;
        #20 data_in = 8'hde;
        data_in_valid = 1;
        #20 data_in = 8'hdf;
        data_in_valid = 1;
        #20 data_in = 8'he0;
        data_in_valid = 1;
        #20 data_in = 8'he1;
        data_in_valid = 1;
        #20 data_in = 8'he2;
        data_in_valid = 1;
        #20 data_in = 8'he3;
        data_in_valid = 1;
        #20 data_in = 8'he4;
        data_in_valid = 1;
        #20 data_in = 8'he5;
        data_in_valid = 1;
        #20 data_in = 8'he6;
        data_in_valid = 1;
        #20 data_in = 8'he7;
        data_in_valid = 1;
        #20 data_in = 8'he8;
        data_in_valid = 1;
        #20 data_in = 8'he9;
        data_in_valid = 1;
        #20 data_in = 8'hea;
        data_in_valid = 1;
        #20 data_in = 8'heb;
        data_in_valid = 1;
        #20 data_in = 8'hec;
        data_in_valid = 1;
        #20 data_in = 8'hed;
        data_in_valid = 1;
        #20 data_in = 8'hee;
        data_in_valid = 1;
        #20 data_in = 8'hef;
        data_in_valid = 1;
        #20 data_in = 8'hf0;
        data_in_valid = 1;
        #20 data_in = 8'hf1;
        data_in_valid = 1;
        #20 data_in = 8'hf2;
        data_in_valid = 1;
        #20 data_in = 8'hf3;
        data_in_valid = 1;
        #20 data_in = 8'hf4;
        data_in_valid = 1;
        #20 data_in = 8'hf5;
        data_in_valid = 1;
        #20 data_in = 8'hf6;
        data_in_valid = 1;
        #20 data_in = 8'hf7;
        data_in_valid = 1;
        #20 data_in = 8'hf8;
        data_in_valid = 1;
        #20 data_in = 8'hf9;
        data_in_valid = 1;
        #20 data_in = 8'hfa;
        data_in_valid = 1;
        #20 data_in = 8'hfb;
        data_in_valid = 1;
        #20 data_in = 8'hfc;
        data_in_valid = 1;
        #20 data_in = 8'hfd;
        data_in_valid = 1;
        #20 data_in = 8'hfe;
        data_in_valid = 1;
        #20 data_in = 8'hff;
        data_in_valid = 1;
        #20 data_in = 8'h00;
        data_in_valid = 0;
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input data_in_valid,
    output [7:0] data_out,
    output data_out_valid
);

    reg [7:0] data_out_reg;
    reg data_out_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 8'h00;
            data_out_valid_reg <= 1'b0;
        end else if (data_in_valid) begin
            data_out_reg <= data_in;
            data_out_valid_reg <= 1'b1;
        end else begin
            data_out_valid_reg <= 1'b0;
        end
    end

    assign data_out = data_out_reg;
    assign data_out_valid = data_out_valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg rst_n;
   