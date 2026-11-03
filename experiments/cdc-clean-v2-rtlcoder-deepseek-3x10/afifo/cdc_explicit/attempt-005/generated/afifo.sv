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

	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;

	reg [ADDR_WIDTH-1:0] wr_ptr;
	reg [ADDR_WIDTH-1:0] rd_ptr;
	reg [ADDR_WIDTH-1:0] next_wr_ptr;
	reg [ADDR_WIDTH-1:0] next_rd_ptr;

	reg [WIDTH-1:0] mem [0:DEPTH-1];

	wire [ADDR_WIDTH-1:0] wr_ptr_sync;
	wire [ADDR_WIDTH-1:0] rd_ptr_sync;

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg2 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg2 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg3 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg3 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg4 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg4 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg5 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg5 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg6 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg6 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg7 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg7 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg8 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg8 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg9 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg9 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg10 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg10 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg11 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg11 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg12 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg12 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg13 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg13 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg14 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg14 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg15 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg15 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg16 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg16 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg17 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg17 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg18 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg18 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg19 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg19 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg20 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg20 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg21 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg21 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg22 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg22 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg23 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg23 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg24 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg24 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg25 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg25 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg26 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg26 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg27 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg27 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg28 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg28 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg29 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg29 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg30 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg30 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg31 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg31 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg32 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg32 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg33 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg33 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg34 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg34 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg35 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg35 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg36 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg36 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg37 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg37 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg38 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg38 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg39 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg39 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg40 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg40 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg41 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg41 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg42 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg42 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg43 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg43 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg44 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg44 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg45 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg45 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg46 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg46 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg47 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg47 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg48 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg48 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg49 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg49 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg50 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg50 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg51 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg51 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg52 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg52 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg53 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg53 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg54 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg54 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg55 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg55 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg56 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg56 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg57 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg57 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg58 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg58 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg59 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg59 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg60 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg60 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg61 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg61 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg62 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg62 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg63 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg63 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg64 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg64 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg65 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg65 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg66 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg66 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg67 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg67 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg68 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg68 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg69 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg69 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg70 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg70 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg71 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg71 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg72 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg72 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg73 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg73 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg74 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg74 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg75 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg75 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg76 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg76 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg77 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg77 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg78 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg78 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg79 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg79 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg80 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg80 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg81 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg81 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg82 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg82 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg83 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg83 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg84 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg84 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg85 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg85 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg86 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg86 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg87 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg87 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg88 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg88 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg89 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg89 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg90 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg90 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg91 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg91 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg92 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg92 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg93 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg93 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg94 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg94 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg95 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg95 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg96 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg96 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg97 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg97 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg98 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg98 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg99 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg99 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg100 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg100 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg101 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg101 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg102 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg102 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg103 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg103 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg104 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg104 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg105 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg105 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg106 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg106 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg107 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg107 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg108 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg108 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg109 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg109 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg110 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg110 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg111 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg111 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg112 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg112 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg113 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg113 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg114 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg114 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg115 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg115 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg116 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg116 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg117 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg117 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg118 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg118 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg119 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg119 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg120 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg120 [0:NFF-1];

	reg [ADDR_WIDTH-1:0] wr_ptr_sync_reg121 [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_sync_reg121 [0:NFF-1];

	reg [ADDR_WIDTH-1:0