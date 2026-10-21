```verilog
module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH  = 16,
	parameter NFF    = 2,
	parameter [0:0]  WRITE_ON_POSEDGE = 1'b1,
	parameter [0:0]  OPT_REGISTER_READS = 1'b1
) (
	input  wire            i_wclk,
	input  wire            i_wr_reset_n,
	input  wire            i_wr,
	input  wire [WIDTH-1:0] i_wr_data,
	output reg             o_wr_full,
	input  wire            i_rclk,
	input  wire            i_rd_reset_n,
	input  wire            i_rd,
	output reg [WIDTH-1:0] o_rd_data,
	output reg             o_rd_empty
);

	localparam GRANT_WIDTH = WIDTH + 2;
	localparam GRANT_MASK  = {WIDTH{1'b0}, 2'b11};
	localparam GRANT_ZERO  = {WIDTH{1'b0}, 2'b00};
	localparam GRANT_ONE   = {WIDTH{1'b0}, 2'b01};
	localparam GRANT_TWO   = {WIDTH{1'b0}, 2'b10};

	// Write Pointer (Gray Code)
	reg [LGFIFO-1:0] w_ptr_gray;
	// Read Pointer (Gray Code)
	reg [LGFIFO-1:0] r_ptr_gray;
	// Write Pointer (Binary)
	reg [LGFIFO-1:0] w_ptr_bin;
	// Read Pointer (Binary)
	reg [LGFIFO-1:0] r_ptr_bin;
	// Write Pointer (Gray) for Full detection
	reg [LGFIFO-1:0] w_ptr_gray_next;
	// Read Pointer (Gray) for Empty detection
	reg [LGFIFO-1:0] r_ptr_gray_next;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed;
	// Write Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed2;
	// Read Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed2;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed3;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed3;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed4;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed4;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed5;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed5;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed6;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed6;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed7;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed7;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed8;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed8;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed9;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed9;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed10;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed10;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed11;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed11;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed12;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed12;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed13;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed13;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed14;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed14;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed15;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed15;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed16;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed16;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed17;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed17;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed18;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed18;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed19;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed19;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed20;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed20;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed21;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed21;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed22;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed22;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed23;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed23;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed24;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed24;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed25;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed25;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed26;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed26;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed27;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed27;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed28;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed28;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed29;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed29;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed30;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed30;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed31;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed31;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed32;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed32;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed33;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed33;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed34;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed34;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed35;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed35;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed36;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed36;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed37;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed37;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed38;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed38;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed39;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed39;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed40;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed40;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed41;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed41;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed42;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed42;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed43;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed43;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed44;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed44;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed45;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed45;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed46;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed46;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed47;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed47;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed48;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed48;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed49;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed49;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed50;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed50;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed51;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed51;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed52;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed52;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed53;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed53;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed54;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed54;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed55;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed55;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed56;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed56;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed57;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed57;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed58;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed58;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed59;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed59;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed60;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed60;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed61;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed61;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed62;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed62;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed63;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed63;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed64;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed64;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed65;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed65;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed66;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed66;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed67;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed67;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed68;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed68;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed69;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed69;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed70;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed70;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed71;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed71;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed72;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed72;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed73;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed73;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed74;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed74;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed75;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed75;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed76;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed76;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed77;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed77;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed78;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed78;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed79;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed79;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed80;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed80;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed81;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed81;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed82;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed82;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed83;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed83;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed84;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed84;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed85;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed85;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed86;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed86;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed87;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed87;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed88;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed88;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed89;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed89;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed90;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed90;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed91;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed91;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed92;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed92;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed93;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed93;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed94;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed94;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed95;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed95;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed96;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed96;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed97;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed97;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed98;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed98;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed99;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed99;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed100;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed100;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed101;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed101;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed102;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed102;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed103;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed103;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed104;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed104;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed105;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed105;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed106;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed106;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed107;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed107;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed108;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed108;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed109;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed109;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed110;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed110;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed111;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed111;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed112;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed112;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed113;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed113;
	// Write Pointer (Gray) for Empty detection (delayed)
	reg [LGFIFO-1:0] r_ptr_gray_delayed114;
	// Read Pointer (Gray) for Full detection (delayed)
	reg [LGFIFO-1:0] w_ptr_gray_delayed114;
	// Write Pointer (Gray