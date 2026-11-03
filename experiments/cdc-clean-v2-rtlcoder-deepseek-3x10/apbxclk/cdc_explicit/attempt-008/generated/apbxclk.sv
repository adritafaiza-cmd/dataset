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

	reg [DW-1:0] S_APB_PRDATA_reg;
	reg S_APB_PSLVERR_reg;
	reg S_APB_PREADY_reg;
	reg [DW-1:0] M_APB_PRDATA_reg;
	reg M_APB_PSLVERR_reg;
	reg M_APB_PREADY_reg;
	reg [DW-1:0] M_APB_PWDATA_reg;
	reg [DW/8-1:0] M_APB_PWSTRB_reg;
	reg [2:0] M_APB_PPROT_reg;
	reg [AW-1:0] M_APB_PADDR_reg;
	reg M_APB_PWRITE_reg;
	reg M_APB_PENABLE_reg;
	reg M_APB_PSEL_reg;
	reg M_PRESETn_reg;
	reg [DW-1:0] S_APB_PWDATA_reg;
	reg [DW/8-1:0] S_APB_PWSTRB_reg;
	reg [2:0] S_APB_PPROT_reg;
	reg [AW-1:0] S_APB_PADDR_reg;
	reg S_APB_PWRITE_reg;
	reg S_APB_PENABLE_reg;
	reg S_APB_PSEL_reg;
	reg S_PRESETn_reg;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			S_APB_PRDATA_reg <= {DW{1'b0}};
			S_APB_PSLVERR_reg <= 1'b0;
			S_APB_PREADY_reg <= 1'b0;
			S_APB_PWDATA_reg <= {DW{1'b0}};
			S_APB_PWSTRB_reg <= {DW/8{1'b0}};
			S_APB_PPROT_reg <= {3{1'b0}};
			S_APB_PADDR_reg <= {AW{1'b0}};
			S_APB_PWRITE_reg <= 1'b0;
			S_APB_PENABLE_reg <= 1'b0;
			S_APB_PSEL_reg <= 1'b0;
			S_PRESETn_reg <= 1'b0;
		end else begin
			S_APB_PRDATA_reg <= S_APB_PRDATA;
			S_APB_PSLVERR_reg <= S_APB_PSLVERR;
			S_APB_PREADY_reg <= S_APB_PREADY;
			S_APB_PWDATA_reg <= S_APB_PWDATA;
			S_APB_PWSTRB_reg <= S_APB_PWSTRB;
			S_APB_PPROT_reg <= S_APB_PPROT;
			S_APB_PADDR_reg <= S_APB_PADDR;
			S_APB_PWRITE_reg <= S_APB_PWRITE;
			S_APB_PENABLE_reg <= S_APB_PENABLE;
			S_APB_PSEL_reg <= S_APB_PSEL;
			S_PRESETn_reg <= S_PRESETn;
		end
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (~M_PRESETn) begin
			M_APB_PRDATA_reg <= {DW{1'b0}};
			M_APB_PSLVERR_reg <= 1'b0;
			M_APB_PREADY_reg <= 1'b0;
			M_APB_PWDATA_reg <= {DW{1'b0}};
			M_APB_PWSTRB_reg <= {DW/8{1'b0}};
			M_APB_PPROT_reg <= {3{1'b0}};
			M_APB_PADDR_reg <= {AW{1'b0}};
			M_APB_PWRITE_reg <= 1'b0;
			M_APB_PENABLE_reg <= 1'b0;
			M_APB_PSEL_reg <= 1'b0;
			M_PRESETn_reg <= 1'b0;
		end else begin
			M_APB_PRDATA_reg <= M_APB_PRDATA;
			M_APB_PSLVERR_reg <= M_APB_PSLVERR;
			M_APB_PREADY_reg <= M_APB_PREADY;
			M_APB_PWDATA_reg <= M_APB_PWDATA;
			M_APB_PWSTRB_reg <= M_APB_PWSTRB;
			M_APB_PPROT_reg <= M_APB_PPROT;
			M_APB_PADDR_reg <= M_APB_PADDR;
			M_APB_PWRITE_reg <= M_APB_PWRITE;
			M_APB_PENABLE_reg <= M_APB_PENABLE;
			M_APB_PSEL_reg <= M_APB_PSEL;
			M_PRESETn_reg <= M_PRESETn;
		end
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				S_APB_PREADY <= 1'b1;
			end else begin
				S_APB_PREADY <= S_APB_PREADY_reg;
			end
		end
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (~M_PRESETn) begin
			M_PRESETn <= 1'b0;
		end else begin
			M_PRESETn <= M_PRESETn_reg;
		end
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			S_APB_PRDATA <= {DW{1'b0}};
			S_APB_PSLVERR <= 1'b0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				S_APB_PRDATA <= M_APB_PRDATA_reg;
				S_APB_PSLVERR <= M_APB_PSLVERR_reg;
			end else begin
				S_APB_PRDATA <= S_APB_PRDATA_reg;
				S_APB_PSLVERR <= S_APB_PSLVERR_reg;
			end
		end
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (~M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {DW/8{1'b0}};
			M_APB_PPROT <= {3{1'b0}};
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE && S_APB_PREADY) begin
				M_APB_PSEL <= S_APB_PSEL_reg;
				M_APB_PENABLE <= S_APB_PENABLE_reg;
				M_APB_PADDR <= S_APB_PADDR_reg;
				M_APB_PWRITE <= S_APB_PWRITE_reg;
				M_APB_PWDATA <= S_APB_PWDATA_reg;
				M_APB_PWSTRB <= S_APB_PWSTRB_reg;
				M_APB_PPROT <= S_APB_PPROT_reg;
			end else begin
				M_APB_PSEL <= M_APB_PSEL_reg;
				M_APB_PENABLE <= M_APB_PENABLE_reg;
				M_APB_PADDR <= M_APB_PADDR_reg;
				M_APB_PWRITE <= M_APB_PWRITE_reg;
				M_APB_PWDATA <= M_APB_PWDATA_reg;
				M_APB_PWSTRB <= M_APB_PWSTRB_reg;
				M_APB_PPROT <= M_APB_PPROT_reg;
			end
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
  end

  // Data output verification
  always @(posedge clk) begin
    if (data_out !== data_in) begin
      $display("Error: data_out = %h, expected = %h", data_out, data_in);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;

  // Outputs
  wire [7:0] data_out;

  // Instantiate the DUT
  dut dut_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
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
    #10 data