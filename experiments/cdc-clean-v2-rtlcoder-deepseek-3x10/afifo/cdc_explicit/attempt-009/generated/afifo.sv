Here is the complete Verilog code for the asynchronous FIFO module:

```
module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	localparam	FIFO_DEPTH = 1 << LGFIFO;

	reg [WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO-1:0] wr_ptr;
	reg [LGFIFO-1:0] rd_ptr;
	reg [LGFIFO-1:0] wr_ptr_next;
	reg [LGFIFO-1:0] rd_ptr_next;

	wire wr_ptr_full = (wr_ptr_next == rd_ptr);
	wire rd_ptr_empty = (rd_ptr_next == wr_ptr);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (~i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_next <= 0;
			o_wr_full <= 0;
		end else begin
			wr_ptr <= wr_ptr_next;
			o_wr_full <= wr_ptr_full;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (~i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_next <= 0;
			o_rd_empty <= 1;
		end else begin
			rd_ptr <= rd_ptr_next;
			o_rd_empty <= rd_ptr_empty;
		end
	end

	always @(posedge i_wclk) begin
		if (i_wr && ~o_wr_full) begin
			fifo[wr_ptr] <= i_wr_data;
			wr_ptr_next <= wr_ptr + 1;
		end
	end

	always @(posedge i_rclk) begin
		if (i_rd && ~o_rd_empty) begin
			o_rd_data <= fifo[rd_ptr];
			rd_ptr_next <= rd_ptr + 1;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
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
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign out = shift_reg[index];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
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
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign out = shift_reg[index];

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
    #10 in = 8'h00;
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
    #10 in = 8'h00;
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
    #10 in = 8'