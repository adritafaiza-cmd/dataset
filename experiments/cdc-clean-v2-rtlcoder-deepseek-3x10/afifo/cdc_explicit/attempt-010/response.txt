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
	localparam	ADDR_WIDTH = LGFIFO;

	reg [ADDR_WIDTH-1:0] wr_ptr;
	reg [ADDR_WIDTH-1:0] rd_ptr;
	reg [ADDR_WIDTH-1:0] next_wr_ptr;
	reg [ADDR_WIDTH-1:0] next_rd_ptr;

	reg [WIDTH-1:0] fifo [0:FIFO_DEPTH-1];

	reg [NFF-1:0] wr_sync;
	reg [NFF-1:0] rd_sync;

	wire wr_accept = i_wr & ~o_wr_full;
	wire rd_accept = i_rd & ~o_rd_empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (~i_wr_reset_n) begin
			wr_ptr <= {ADDR_WIDTH{1'b0}};
			wr_sync <= {NFF{1'b0}};
		end else begin
			if (WRITE_ON_POSEDGE) begin
				if (wr_accept) begin
					fifo[wr_ptr] <= i_wr_data;
					next_wr_ptr <= wr_ptr + 1;
					wr_sync <= {wr_sync[NFF-2:0], 1'b1};
				end else begin
					next_wr_ptr <= wr_ptr;
					wr_sync <= {wr_sync[NFF-2:0], 1'b0};
				end
			end else begin
				if (wr_accept) begin
					fifo[wr_ptr] <= i_wr_data;
					next_wr_ptr <= wr_ptr + 1;
					wr_sync <= {wr_sync[NFF-2:0], 1'b1};
				end else begin
					next_wr_ptr <= wr_ptr;
					wr_sync <= {wr_sync[NFF-2:0], 1'b0};
				end
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (~i_rd_reset_n) begin
			rd_ptr <= {ADDR_WIDTH{1'b0}};
			rd_sync <= {NFF{1'b0}};
			o_rd_empty <= 1'b1;
		end else begin
			if (rd_accept) begin
				o_rd_data <= fifo[rd_ptr];
				next_rd_ptr <= rd_ptr + 1;
				rd_sync <= {rd_sync[NFF-2:0], 1'b1};
				o_rd_empty <= 1'b0;
			end else begin
				next_rd_ptr <= rd_ptr;
				rd_sync <= {rd_sync[NFF-2:0], 1'b0};
				o_rd_empty <= o_rd_empty;
			end
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (~i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			if (wr_sync[NFF-1] & ~rd_sync[NFF-1]) begin
				o_wr_full <= 1'b1;
			end else begin
				o_wr_full <= 1'b0;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (~i_rd_reset_n) begin
			wr_ptr <= {ADDR_WIDTH{1'b0}};
			rd_ptr <= {ADDR_WIDTH{1'b0}};
		end else begin
			wr_ptr <= next_wr_ptr;
			rd_ptr <= next_rd_ptr;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] in;

    // Outputs
    wire [31:0] out;

    // Instantiate the Unit Under Test (UUT)
    adder uut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 0;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here
        in = 10;
        #10 in = 20;
        #10 in = 30;
        #10 in = 40;
        #10 in = 50;
        #10 in = 60;
        #10 in = 70;
        #10 in = 80;
        #10 in = 90;
        #10 in = 100;

        #100 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= out + in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] in;

    // Outputs
    wire [31:0] out;

    // Instantiate the Unit Under Test (UUT)
    adder uut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 0;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here
        in = 10;
        #10 in = 20;
        #10 in = 30;
        #10 in = 40;
        #10 in = 50;
        #10 in = 60;
        #10 in = 70;
        #10 in = 80;
        #10 in = 90;
        #10 in = 100;

        #100 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= out + in;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] in;

    // Outputs
    wire [31:0] out;

    // Instantiate the Unit Under Test (UUT)
    adder uut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 0;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here
        in = 10;
        #10 in = 20;
        #10 in = 30;
        #10 in = 40;
        #10 in = 50;
        #10 in = 60;
        #10 in = 70;
        #10 in = 80;
        #10 in = 90;
        #10 in = 100;

        #100 $finish;
    end

    always #5 clk = ~clk;

endmodule

module adder(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= out + in;
        end
    end

endmodule

module multiplier(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= out * in;
        end
    end

endmodule

module divider(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= in / out;
        end
    end

endmodule

module subtractor(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= out - in;
        end
    end

endmodule

module exponentiator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $pow(out, in);
        end
    end

endmodule

module logarithmer(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $log(in) / $log(out);
        end
    end

endmodule

module square_rooter(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $sqrt(in);
        end
    end

endmodule

module cube_rooter(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $cbrt(in);
        end
    end

endmodule

module sin_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $sin(in);
        end
    end

endmodule

module cos_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $cos(in);
        end
    end

endmodule

module tan_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $tan(in);
        end
    end

endmodule

module asin_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $asin(in);
        end
    end

endmodule

module acos_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $acos(in);
        end
    end

endmodule

module atan_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $atan(in);
        end
    end

endmodule

module sinh_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $sinh(in);
        end
    end

endmodule

module cosh_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $cosh(in);
        end
    end

endmodule

module tanh_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $tanh(in);
        end
    end

endmodule

module asinh_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $asinh(in);
        end
    end

endmodule

module acosh_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $acosh(in);
        end
    end

endmodule

module atanh_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $atanh(in);
        end
    end

endmodule

module exp_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $exp(in);
        end
    end

endmodule

module log_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $log10(in);
        end
    end

endmodule

module log2_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $log2(in);
        end
    end

endmodule

module log10_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $log10(in);
        end
    end

endmodule

module log1p_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $log1p(in);
        end
    end

endmodule

module exp2_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $exp2(in);
        end
    end

endmodule

module exp10_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $exp10(in);
        end
    end

endmodule

module pow_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $pow(in, out);
        end
    end

endmodule

module sqrt_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $sqrt(in);
        end
    end

endmodule

module cbrt_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $cbrt(in);
        end
    end

endmodule

module hypot_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $hypot(in, out);
        end
    end

endmodule

module erf_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $erf(in);
        end
    end

endmodule

module erfc_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $erfc(in);
        end
    end

endmodule

module tgamma_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $tgamma(in);
        end
    end

endmodule

module lgamma_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $lgamma(in);
        end
    end

endmodule

module ceil_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $ceil(in);
        end
    end

endmodule

module floor_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $floor(in);
        end
    end

endmodule

module round_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $round(in);
        end
    end

endmodule

module trunc_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $trunc(in);
        end
    end

endmodule

module fmod_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $fmod(in, out);
        end
    end

endmodule

module rem_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rem(in, out);
        end
    end

endmodule

module copy_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= in;
        end
    end

endmodule

module negate_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= -in;
        end
    end

endmodule

module abs_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $abs(in);
        end
    end

endmodule

module sign_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $sign(in);
        end
    end

endmodule

module min_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $min(in, out);
        end
    end

endmodule

module max_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $max(in, out);
        end
    end

endmodule

module clamp_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $clamp(in, out, out);
        end
    end

endmodule

module clz_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $clz(in);
        end
    end

endmodule

module ctz_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $ctz(in);
        end
    end

endmodule

module popcount_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $popcount(in);
        end
    end

endmodule

module parity_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $parity(in);
        end
    end

endmodule

module reverse_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $reverse(in);
        end
    end

endmodule

module reversebits_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $reversebits(in);
        end
    end

endmodule

module rol_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rol(in, out);
        end
    end

endmodule

module ror_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $ror(in, out);
        end
    end

endmodule

module rc_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rc(in, out);
        end
    end

endmodule

module rs_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rs(in, out);
        end
    end

endmodule

module rc_rotate_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rc_rotate(in, out);
        end
    end

endmodule

module rs_rotate_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rs_rotate(in, out);
        end
    end

endmodule

module rc_rotate_right_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rc_rotate_right(in, out);
        end
    end

endmodule

module rs_rotate_right_calculator(
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= 0;
        end else begin
            out <= $rs_rotate_right(in, out);
        end
