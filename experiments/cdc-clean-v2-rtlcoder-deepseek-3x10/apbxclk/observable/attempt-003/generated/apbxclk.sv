Sure, here is the complete Verilog-2001 code for the APB clock-domain bridge module:

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

	reg [AW-1:0] S_APB_PADDR_sync;
	reg S_APB_PWRITE_sync;
	reg [DW-1:0] S_APB_PWDATA_sync;
	reg [DW/8-1:0] S_APB_PWSTRB_sync;
	reg [2:0] S_APB_PPROT_sync;
	reg S_APB_PSEL_sync;
	reg S_APB_PENABLE_sync;

	reg [AW-1:0] M_APB_PADDR_sync;
	reg M_APB_PWRITE_sync;
	reg [DW-1:0] M_APB_PWDATA_sync;
	reg [DW/8-1:0] M_APB_PWSTRB_sync;
	reg [2:0] M_APB_PPROT_sync;
	reg M_APB_PSEL_sync;
	reg M_APB_PENABLE_sync;

	reg [DW-1:0] M_APB_PRDATA_sync;
	reg M_APB_PSLVERR_sync;

	reg [1:0] state_s;
	reg [1:0] state_m;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			S_APB_PADDR_sync <= {AW{1'b0}};
			S_APB_PWRITE_sync <= 1'b0;
			S_APB_PWDATA_sync <= {DW{1'b0}};
			S_APB_PWSTRB_sync <= {DW/8{1'b0}};
			S_APB_PPROT_sync <= {3{1'b0}};
			S_APB_PSEL_sync <= 1'b0;
			S_APB_PENABLE_sync <= 1'b0;
			state_s <= 2'b00;
		end else begin
			case (state_s)
				2'b00: begin
					if (S_APB_PSEL && S_APB_PENABLE) begin
						S_APB_PADDR_sync <= S_APB_PADDR;
						S_APB_PWRITE_sync <= S_APB_PWRITE;
						S_APB_PWDATA_sync <= S_APB_PWDATA;
						S_APB_PWSTRB_sync <= S_APB_PWSTRB;
						S_APB_PPROT_sync <= S_APB_PPROT;
						S_APB_PSEL_sync <= 1'b1;
						S_APB_PENABLE_sync <= 1'b1;
						state_s <= 2'b01;
					end else begin
						S_APB_PSEL_sync <= 1'b0;
						S_APB_PENABLE_sync <= 1'b0;
					end
				end
				2'b01: begin
					if (M_APB_PREADY) begin
						S_APB_PSEL_sync <= 1'b0;
						S_APB_PENABLE_sync <= 1'b0;
						state_s <= 2'b00;
					end
				end
			endcase
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			M_APB_PADDR_sync <= {AW{1'b0}};
			M_APB_PWRITE_sync <= 1'b0;
			M_APB_PWDATA_sync <= {DW{1'b0}};
			M_APB_PWSTRB_sync <= {DW/8{1'b0}};
			M_APB_PPROT_sync <= {3{1'b0}};
			M_APB_PSEL_sync <= 1'b0;
			M_APB_PENABLE_sync <= 1'b0;
			M_APB_PRDATA_sync <= {DW{1'b0}};
			M_APB_PSLVERR_sync <= 1'b0;
			state_m <= 2'b00;
		end else begin
			case (state_m)
				2'b00: begin
					if (M_APB_PREADY) begin
						M_APB_PADDR_sync <= S_APB_PADDR_sync;
						M_APB_PWRITE_sync <= S_APB_PWRITE_sync;
						M_APB_PWDATA_sync <= S_APB_PWDATA_sync;
						M_APB_PWSTRB_sync <= S_APB_PWSTRB_sync;
						M_APB_PPROT_sync <= S_APB_PPROT_sync;
						M_APB_PSEL_sync <= 1'b1;
						M_APB_PENABLE_sync <= 1'b1;
						state_m <= 2'b01;
					end else begin
						M_APB_PSEL_sync <= 1'b0;
						M_APB_PENABLE_sync <= 1'b0;
					end
				end
				2'b01: begin
					if (M_APB_PREADY) begin
						M_APB_PSEL_sync <= 1'b0;
						M_APB_PENABLE_sync <= 1'b0;
						M_APB_PRDATA_sync <= M_APB_PRDATA;
						M_APB_PSLVERR_sync <= M_APB_PSLVERR;
						state_m <= 2'b10;
					end
				end
				2'b10: begin
					if (S_APB_PREADY) begin
						M_APB_PSEL_sync <= 1'b0;
						M_APB_PENABLE_sync <= 1'b0;
						state_m <= 2'b00;
					end
				end
			endcase
		end
	end

	assign M_PRESETn = ~S_PRESETn;
	assign M_APB_PADDR = M_APB_PADDR_sync;
	assign M_APB_PWRITE = M_APB_PWRITE_sync;
	assign M_APB_PWDATA = M_APB_PWDATA_sync;
	assign M_APB_PWSTRB = M_APB_PWSTRB_sync;
	assign M_APB_PPROT = M_APB_PPROT_sync;
	assign M_APB_PRDATA = M_APB_PRDATA_sync;
	assign M_APB_PSLVERR = M_APB_PSLVERR_sync;

	assign S_APB_PREADY = (state_s == 2'b00);
	assign S_APB_PRDATA = M_APB_PRDATA_sync;
	assign S_APB_PSLVERR = M_APB_PSLVERR_sync;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_reg <= 8'h00;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 $finish;
end

always #5