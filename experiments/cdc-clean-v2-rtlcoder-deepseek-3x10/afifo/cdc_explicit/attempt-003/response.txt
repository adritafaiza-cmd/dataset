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

	localparam	FIFOSIZE = 1 << LGFIFO;

	reg	[WIDTH-1:0]	mem [FIFOSIZE-1:0];
	reg	[LGFIFO-1:0]	wptr, rptr;
	reg			wptr_inc, rptr_inc;
	reg			wptr_reset, rptr_reset;
	reg			wptr_inc_ack, rptr_inc_ack;

	wire		wptr_inc_ack_sync;
	wire		wptr_inc_ack_sync_d1;
	wire		wptr_inc_ack_sync_d2;
	wire		wptr_inc_ack_sync_d3;

	wire		rptr_inc_ack_sync;
	wire		rptr_inc_ack_sync_d1;
	wire		rptr_inc_ack_sync_d2;
	wire		rptr_inc_ack_sync_d3;

	wire		wptr_reset_sync;
	wire		wptr_reset_sync_d1;
	wire		wptr_reset_sync_d2;
	wire		wptr_reset_sync_d3;

	wire		rptr_reset_sync;
	wire		rptr_reset_sync_d1;
	wire		rptr_reset_sync_d2;
	wire		rptr_reset_sync_d3;

	wire		wptr_inc_sync;
	wire		wptr_inc_sync_d1;
	wire		wptr_inc_sync_d2;
	wire		wptr_inc_sync_d3;

	wire		rptr_inc_sync;
	wire		rptr_inc_sync_d1;
	wire		rptr_inc_sync_d2;
	wire		rptr_inc_sync_d3;

	wire		wptr_inc_sync_d2_ack;
	wire		wptr_inc_sync_d3_ack;

	wire		rptr_inc_sync_d2_ack;
	wire		rptr_inc_sync_d3_ack;

	wire		wptr_reset_sync_d2_ack;
	wire		wptr_reset_sync_d3_ack;

	wire		rptr_reset_sync_d2_ack;
	wire		rptr_reset_sync_d3_ack;

	wire		wptr_inc_sync_d1_ack;
	wire		rptr_inc_sync_d1_ack;

	wire		wptr_inc_sync_d2_ack_d1;
	wire		wptr_inc_sync_d3_ack_d1;

	wire		rptr_inc_sync_d2_ack_d1;
	wire		rptr_inc_sync_d3_ack_d1;

	wire		wptr_reset_sync_d2_ack_d1;
	wire		wptr_reset_sync_d3_ack_d1;

	wire		rptr_reset_sync_d2_ack_d1;
	wire		rptr_reset_sync_d3_ack_d1;

	wire		wptr_inc_sync_d1_ack_d1;
	wire		rptr_inc_sync_d1_ack_d1;

	wire		wptr_inc_sync_d2_ack_d2;
	wire		wptr_inc_sync_d3_ack_d2;

	wire		rptr_inc_sync_d2_ack_d2;
	wire		rptr_inc_sync_d3_ack_d2;

	wire		wptr_reset_sync_d2_ack_d2;
	wire		wptr_reset_sync_d3_ack_d2;

	wire		rptr_reset_sync_d2_ack_d2;
	wire		rptr_reset_sync_d3_ack_d2;

	wire		wptr_inc_sync_d1_ack_d2;
	wire		rptr_inc_sync_d1_ack_d2;

	wire		wptr_inc_sync_d2_ack_d3;
	wire		wptr_inc_sync_d3_ack_d3;

	wire		rptr_inc_sync_d2_ack_d3;
	wire		rptr_inc_sync_d3_ack_d3;

	wire		wptr_reset_sync_d2_ack_d3;
	wire		wptr_reset_sync_d3_ack_d3;

	wire		rptr_reset_sync_d2_ack_d3;
	wire		rptr_reset_sync_d3_ack_d3;

	wire		wptr_inc_sync_d1_ack_d3;
	wire		rptr_inc_sync_d1_ack_d3;

	wire		wptr_inc_sync_d2_ack_d4;
	wire		wptr_inc_sync_d3_ack_d4;

	wire		rptr_inc_sync_d2_ack_d4;
	wire		rptr_inc_sync_d3_ack_d4;

	wire		wptr_reset_sync_d2_ack_d4;
	wire		wptr_reset_sync_d3_ack_d4;

	wire		rptr_reset_sync_d2_ack_d4;
	wire		rptr_reset_sync_d3_ack_d4;

	wire		wptr_inc_sync_d1_ack_d4;
	wire		rptr_inc_sync_d1_ack_d4;

	wire		wptr_inc_sync_d2_ack_d5;
	wire		wptr_inc_sync_d3_ack_d5;

	wire		rptr_inc_sync_d2_ack_d5;
	wire		rptr_inc_sync_d3_ack_d5;

	wire		wptr_reset_sync_d2_ack_d5;
	wire		wptr_reset_sync_d3_ack_d5;

	wire		rptr_reset_sync_d2_ack_d5;
	wire		rptr_reset_sync_d3_ack_d5;

	wire		wptr_inc_sync_d1_ack_d5;
	wire		rptr_inc_sync_d1_ack_d5;

	wire		wptr_inc_sync_d2_ack_d6;
	wire		wptr_inc_sync_d3_ack_d6;

	wire		rptr_inc_sync_d2_ack_d6;
	wire		rptr_inc_sync_d3_ack_d6;

	wire		wptr_reset_sync_d2_ack_d6;
	wire		wptr_reset_sync_d3_ack_d6;

	wire		rptr_reset_sync_d2_ack_d6;
	wire		rptr_reset_sync_d3_ack_d6;

	wire		wptr_inc_sync_d1_ack_d6;
	wire		rptr_inc_sync_d1_ack_d6;

	wire		wptr_inc_sync_d2_ack_d7;
	wire		wptr_inc_sync_d3_ack_d7;

	wire		rptr_inc_sync_d2_ack_d7;
	wire		rptr_inc_sync_d3_ack_d7;

	wire		wptr_reset_sync_d2_ack_d7;
	wire		wptr_reset_sync_d3_ack_d7;

	wire		rptr_reset_sync_d2_ack_d7;
	wire		rptr_reset_sync_d3_ack_d7;

	wire		wptr_inc_sync_d1_ack_d7;
	wire		rptr_inc_sync_d1_ack_d7;

	wire		wptr_inc_sync_d2_ack_d8;
	wire		wptr_inc_sync_d3_ack_d8;

	wire		rptr_inc_sync_d2_ack_d8;
	wire		rptr_inc_sync_d3_ack_d8;

	wire		wptr_reset_sync_d2_ack_d8;
	wire		wptr_reset_sync_d3_ack_d8;

	wire		rptr_reset_sync_d2_ack_d8;
	wire		rptr_reset_sync_d3_ack_d8;

	wire		wptr_inc_sync_d1_ack_d8;
	wire		rptr_inc_sync_d1_ack_d8;

	wire		wptr_inc_sync_d2_ack_d9;
	wire		wptr_inc_sync_d3_ack_d9;

	wire		rptr_inc_sync_d2_ack_d9;
	wire		rptr_inc_sync_d3_ack_d9;

	wire		wptr_reset_sync_d2_ack_d9;
	wire		wptr_reset_sync_d3_ack_d9;

	wire		rptr_reset_sync_d2_ack_d9;
	wire		rptr_reset_sync_d3_ack_d9;

	wire		wptr_inc_sync_d1_ack_d9;
	wire		rptr_inc_sync_d1_ack_d9;

	wire		wptr_inc_sync_d2_ack_d10;
	wire		wptr_inc_sync_d3_ack_d10;

	wire		rptr_inc_sync_d2_ack_d10;
	wire		rptr_inc_sync_d3_ack_d10;

	wire		wptr_reset_sync_d2_ack_d10;
	wire		wptr_reset_sync_d3_ack_d10;

	wire		rptr_reset_sync_d2_ack_d10;
	wire		rptr_reset_sync_d3_ack_d10;

	wire		wptr_inc_sync_d1_ack_d10;
	wire		rptr_inc_sync_d1_ack_d10;

	wire		wptr_inc_sync_d2_ack_d11;
	wire		wptr_inc_sync_d3_ack_d11;

	wire		rptr_inc_sync_d2_ack_d11;
	wire		rptr_inc_sync_d3_ack_d11;

	wire		wptr_reset_sync_d2_ack_d11;
	wire		wptr_reset_sync_d3_ack_d11;

	wire		rptr_reset_sync_d2_ack_d11;
	wire		rptr_reset_sync_d3_ack_d11;

	wire		wptr_inc_sync_d1_ack_d11;
	wire		rptr_inc_sync_d1_ack_d11;

	wire		wptr_inc_sync_d2_ack_d12;
	wire		wptr_inc_sync_d3_ack_d12;

	wire		rptr_inc_sync_d2_ack_d12;
	wire		rptr_inc_sync_d3_ack_d12;

	wire		wptr_reset_sync_d2_ack_d12;
	wire		wptr_reset_sync_d3_ack_d12;

	wire		rptr_reset_sync_d2_ack_d12;
	wire		rptr_reset_sync_d3_ack_d12;

	wire		wptr_inc_sync_d1_ack_d12;
	wire		rptr_inc_sync_d1_ack_d12;

	wire		wptr_inc_sync_d2_ack_d13;
	wire		wptr_inc_sync_d3_ack_d13;

	wire		rptr_inc_sync_d2_ack_d13;
	wire		rptr_inc_sync_d3_ack_d13;

	wire		wptr_reset_sync_d2_ack_d13;
	wire		wptr_reset_sync_d3_ack_d13;

	wire		rptr_reset_sync_d2_ack_d13;
	wire		rptr_reset_sync_d3_ack_d13;

	wire		wptr_inc_sync_d1_ack_d13;
	wire		rptr_inc_sync_d1_ack_d13;

	wire		wptr_inc_sync_d2_ack_d14;
	wire		wptr_inc_sync_d3_ack_d14;

	wire		rptr_inc_sync_d2_ack_d14;
	wire		rptr_inc_sync_d3_ack_d14;

	wire		wptr_reset_sync_d2_ack_d14;
	wire		wptr_reset_sync_d3_ack_d14;

	wire		rptr_reset_sync_d2_ack_d14;
	wire		rptr_reset_sync_d3_ack_d14;

	wire		wptr_inc_sync_d1_ack_d14;
	wire		rptr_inc_sync_d1_ack_d14;

	wire		wptr_inc_sync_d2_ack_d15;
	wire		wptr_inc_sync_d3_ack_d15;

	wire		rptr_inc_sync_d2_ack_d15;
	wire		rptr_inc_sync_d3_ack_d15;

	wire		wptr_reset_sync_d2_ack_d15;
	wire		wptr_reset_sync_d3_ack_d15;

	wire		rptr_reset_sync_d2_ack_d15;
	wire		rptr_reset_sync_d3_ack_d15;

	wire		wptr_inc_sync_d1_ack_d15;
	wire		rptr_inc_sync_d1_ack_d15;

	wire		wptr_inc_sync_d2_ack_d16;
	wire		wptr_inc_sync_d3_ack_d16;

	wire		rptr_inc_sync_d2_ack_d16;
	wire		rptr_inc_sync_d3_ack_d16;

	wire		wptr_reset_sync_d2_ack_d16;
	wire		wptr_reset_sync_d3_ack_d16;

	wire		rptr_reset_sync_d2_ack_d16;
	wire		rptr_reset_sync_d3_ack_d16;

	wire		wptr_inc_sync_d1_ack_d16;
	wire		rptr_inc_sync_d1_ack_d16;

	wire		wptr_inc_sync_d2_ack_d17;
	wire		wptr_inc_sync_d3_ack_d17;

	wire		rptr_inc_sync_d2_ack_d17;
	wire		rptr_inc_sync_d3_ack_d17;

	wire		wptr_reset_sync_d2_ack_d17;
	wire		wptr_reset_sync_d3_ack_d17;

	wire		rptr_reset_sync_d2_ack_d17;
	wire		rptr_reset_sync_d3_ack_d17;

	wire		wptr_inc_sync_d1_ack_d17;
	wire		rptr_inc_sync_d1_ack_d17;

	wire		wptr_inc_sync_d2_ack_d18;
	wire		wptr_inc_sync_d3_ack_d18;

	wire		rptr_inc_sync_d2_ack_d18;
	wire		rptr_inc_sync_d3_ack_d18;

	wire		wptr_reset_sync_d2_ack_d18;
	wire		wptr_reset_sync_d3_ack_d18;

	wire		rptr_reset_sync_d2_ack_d18;
	wire		rptr_reset_sync_d3_ack_d18;

	wire		wptr_inc_sync_d1_ack_d18;
	wire		rptr_inc_sync_d1_ack_d18;

	wire		wptr_inc_sync_d2_ack_d19;
	wire		wptr_inc_sync_d3_ack_d19;

	wire		rptr_inc_sync_d2_ack_d19;
	wire		rptr_inc_sync_d3_ack_d19;

	wire		wptr_reset_sync_d2_ack_d19;
	wire		wptr_reset_sync_d3_ack_d19;

	wire		rptr_reset_sync_d2_ack_d19;
	wire		rptr_reset_sync_d3_ack_d19;

	wire		wptr_inc_sync_d1_ack_d19;
	wire		rptr_inc_sync_d1_ack_d19;

	wire		wptr_inc_sync_d2_ack_d20;
	wire		wptr_inc_sync_d3_ack_d20;

	wire		rptr_inc_sync_d2_ack_d20;
	wire		rptr_inc_sync_d3_ack_d20;

	wire		wptr_reset_sync_d2_ack_d20;
	wire		wptr_reset_sync_d3_ack_d20;

	wire		rptr_reset_sync_d2_ack_d20;
	wire		rptr_reset_sync_d3_ack_d20;

	wire		wptr_inc_sync_d1_ack_d20;
	wire		rptr_inc_sync_d1_ack_d20;

	wire		wptr_inc_sync_d2_ack_d21;
	wire		wptr_inc_sync_d3_ack_d21;

	wire		rptr_inc_sync_d2_ack_d21;
	wire		rptr_inc_sync_d3_ack_d21;

	wire		wptr_reset_sync_d2_ack_d21;
	wire		wptr_reset_sync_d3_ack_d21;

	wire		rptr_reset_sync_d2_ack_d21;
	wire		rptr_reset_sync_d3_ack_d21;

	wire		wptr_inc_sync_d1_ack_d21;
	wire		rptr_inc_sync_d1_ack_d21;

	wire		wptr_inc_sync_d2_ack_d22;
	wire		wptr_inc_sync_d3_ack_d22;

	wire		rptr_inc_sync_d2_ack_d22;
	wire		rptr_inc_sync_d3_ack_d22;

	wire		wptr_reset_sync_d2_ack_d22;
	wire		wptr_reset_sync_d3_ack_d22;

	wire		rptr_reset_sync_d2_ack_d22;
	wire		rptr_reset_sync_d3_ack_d22;

	wire		wptr_inc_sync_d1_ack_d22;
	wire		rptr_inc_sync_d1_ack_d22;

	wire		wptr_inc_sync_d2_ack_d23;
	wire		wptr_inc_sync_d3_ack_d23;

	wire		rptr_inc_sync_d2_ack_d23;
	wire		rptr_inc_sync_d3_ack_d23;

	wire		wptr_reset_sync_d2_ack_d23;
	wire		wptr_reset_sync_d3_ack_d23;

	wire		rptr_reset_sync_d2_ack_d23;
	wire		rptr_reset_sync_d3_ack_d23;

	wire		wptr_inc_sync_d1_ack_d23;
	wire		rptr_inc_sync_d1_ack_d23;

	wire		wptr_inc_sync_d2_ack_d24;
	wire		wptr_inc_sync_d3_ack_d24;

	wire		rptr_inc_sync_d2_ack_d24;
	wire		rptr_inc_sync_d3_ack_d24;

	wire		wptr_reset_sync_d2_ack_d24;
	wire		wptr_reset_sync_d3_ack_d24;

	wire		rptr_reset_sync_d2_ack_d24;
	wire		rptr_reset_sync_d3_ack_d24;

	wire		wptr_inc_sync_d1_ack_d24;
	wire		rptr_inc_sync_d1_ack_d24;

	wire		wptr_inc_sync_d2_ack_d25;
	wire		wptr_inc_sync_d3_ack_d25;

	wire		rptr_inc_sync_d2_ack_d25;
	wire		rptr_inc_sync_d3_ack_d25;

	wire		wptr_reset_sync_d2_ack_d25;
	wire		wptr_reset_sync_d3_ack_d25;

	wire		rptr_reset_sync_d2_ack_d25;
	wire		rptr_reset_sync_d3_ack_d25;

	wire		wptr_inc_sync_d1_ack_d25;
	wire		rptr_inc_sync_d1_ack_d25;

	wire		wptr_inc_sync_d2_ack_d26;
	wire		wptr_inc_sync_d3_ack_d26;

	wire		rptr_inc_sync_d2_ack_d26;
	wire		rptr_inc_sync_d3_ack_d26;

	wire		wptr_reset_sync_d2_ack_d26;
	wire		wptr_reset_sync_d3_ack_d26;

	wire		rptr_reset_sync_d2_ack_d26;
	wire		rptr_reset_sync_d3_ack_d26;

	wire		wptr_inc_sync_d1_ack_d26;
	wire		rptr_inc_sync_d1_ack_d26;

	wire		wptr_inc_sync_d2_ack_d27;
	wire		wptr_inc_sync_d3_ack_d27;

	wire		rptr_inc_sync_d2_ack_d27;
	wire		rptr_inc_sync_d3_ack_d27;

	wire		wptr_reset_sync_d2_ack_d27;
	wire		wptr_reset_sync_d3_ack_d27;

	wire		rptr_reset_sync_d2_ack_d27;
	wire		rptr_reset_sync_d3_ack_d27;

	wire		wptr_inc_sync_d1_ack_d27;
	wire		rptr_inc_sync_d1_ack_d27;

	wire		wptr_inc_sync_d2_ack_d28;
	wire		wptr_inc_sync_d3_ack_d28;

	wire		rptr_inc_sync_d2_ack_d28;
	wire		rptr_inc_sync_d3_ack_d28;

	wire		wptr_reset_sync_d2_ack_d28;
	wire		wptr_reset_sync_d3_ack_d28;

	wire		rptr_reset_sync_d2_ack_d28;
	wire		rptr_reset_sync_d3_ack_d28;

	wire		wptr_inc_sync_d1_ack_d28;
	wire		rptr_inc_sync_d1_ack_d28;

	wire		wptr_inc_sync_d2_ack_d29;
	wire		wptr_inc_sync_d3_ack_d29;

	wire		rptr_inc_sync_d2_ack_d29;
	wire		rptr_inc_sync_d3_ack_d29;

	wire		wptr_reset_sync_d2_ack_d29;
	wire		wptr_reset_sync_d3_ack_d29;

	wire		rptr_reset_sync_d2_ack_d29;
	wire		rptr_reset_sync_d3_ack_d29;

	wire		wptr_inc_sync_d1_ack_d29;
	wire		rptr_inc_sync_d1_ack_d29;

	wire		wptr_inc_sync_d2_ack_d30;
	wire		wptr_inc_sync_d3_ack_d30;

	wire		rptr_inc_sync_d2_ack_d30;
	wire		rptr_inc_sync_d3_ack_d30;

	wire		wptr_reset_sync_d2_ack_d30;
	wire		wptr_reset_sync_d3_ack_d30;

	wire		rptr_reset_sync_d2_ack_d30;
	wire		rptr_reset_sync_d3_ack_d30;

	wire		wptr_inc_sync_d1_ack_d30;
	wire		rptr_inc_sync_d1_ack_d30;

	wire		wptr_inc_sync_d2_ack_d31;
	wire		wptr_inc_sync_d3_ack_d31;

	wire		rptr_inc_sync_d2_ack_d31;
	wire		rptr_inc_sync_d3_ack_d31;

	wire		wptr_reset_sync_d2_ack_d31;
	wire		wptr_reset_sync_d3_ack_d31;

	wire		rptr_reset_sync_d2_ack_d31;
	wire		rptr_reset_sync_d3_ack_d31;

	wire		wptr_inc_sync_d1_ack_d31;
	wire		rptr_inc_sync_d1_ack_d31;

	wire		wptr_inc_sync_d2_ack_d32;
	wire		wptr_inc_sync_d3_ack_d32;

	wire		rptr_inc_sync_d2_ack_d32;
	wire		rptr_inc_sync_d3_ack_d32;

	wire		wptr_reset_sync_d2_ack_d32;
	wire		wptr_reset_sync_d3_ack_d32;

	wire		rptr_reset_sync_d2_ack_d32;
	wire		rptr_reset_sync_d3_ack_d32;

	wire		wptr_inc_sync_d1_ack_d32;
	wire		rptr_inc_sync_d1_ack_d32;

	wire		wptr_inc_sync_d2_ack_d33;
	wire		wptr_inc_sync_d3_ack_d33;

	wire		rptr_inc_sync_d2_ack_d33;
	wire		rptr_inc_sync_d3_ack_d33;

	wire		wptr_reset_sync_d2_ack_d33;
	wire		wptr_reset_sync_d3_ack_d33;

	wire		rptr_reset_sync_d2_ack_d33;
	wire		rptr_reset_sync_d3_ack_d33;

	wire		wptr_inc_sync_d1_ack_d33;
	wire		rptr_inc_sync_d1_ack_d33;

	wire		wptr_inc_sync_d2_ack_d34;
	wire		wptr_inc_sync_d3_ack_d34;

	wire		rptr_inc_sync_d2_ack_d34;
	wire		rptr_inc_sync_d3_ack_d34;

	wire		wptr_reset_sync_d2_ack_d34;
	wire		wptr_reset_sync_d3_ack_d34;

	wire		rptr_reset_sync_d2_ack_d34;
	wire		rptr_reset_sync_d3_ack_d34;

	wire		wptr_inc_sync_d1_ack_d34;
	wire		rptr_inc_sync_d1_ack_d34;

	wire		wptr_inc_sync_d2_ack_d35;
	wire		wptr_inc_sync_d3_ack_d35;

	wire		rptr_inc_sync_d2_ack_d35;
	wire		rptr_inc_sync_d3_ack_d