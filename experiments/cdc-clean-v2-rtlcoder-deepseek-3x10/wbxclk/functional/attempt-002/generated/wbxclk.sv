Here is the complete Verilog code for the pipelined Wishbone clock-domain bridge:

```
module wbxclk #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk, i_reset,
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[(AW-1):0]	i_wb_addr,
		input	wire	[(DW-1):0]	i_wb_data,
		input	wire	[(DW/8-1):0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[(DW-1):0]	o_wb_data,
		output	reg			o_wb_err,
		input	wire			i_xclk_clk,
		output	reg			o_xclk_cyc,
		output	reg			o_xclk_stb,
		output	reg			o_xclk_we,
		output	reg	[(AW-1):0]	o_xclk_addr,
		output	reg	[(DW-1):0]	o_xclk_data,
		output	reg	[(DW/8-1):0]	o_xclk_sel,
		input	wire			i_xclk_stall,
		input	wire			i_xclk_ack,
		input	wire	[(DW-1):0]	i_xclk_data,
		input	wire			i_xclk_err
	);

	reg [LGFIFO:0] wb_fifo_count;
	reg [LGFIFO:0] xclk_fifo_count;
	reg [LGFIFO:0] wb_fifo_count_next;
	reg [LGFIFO:0] xclk_fifo_count_next;

	reg [DW-1:0] wb_data_reg;
	reg [DW-1:0] xclk_data_reg;
	reg [DW/8-1:0] wb_sel_reg;
	reg [DW/8-1:0] xclk_sel_reg;
	reg [AW-1:0] wb_addr_reg;
	reg [AW-1:0] xclk_addr_reg;
	reg wb_we_reg;
	reg xclk_we_reg;

	reg [LGFIFO:0] wb_fifo_count_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next;

	reg [DW-1:0] wb_data_reg_next;
	reg [DW-1:0] xclk_data_reg_next;
	reg [DW/8-1:0] wb_sel_reg_next;
	reg [DW/8-1:0] xclk_sel_reg_next;
	reg [AW-1:0] wb_addr_reg_next;
	reg [AW-1:0] xclk_addr_reg_next;
	reg wb_we_reg_next;
	reg xclk_we_reg_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next;
	reg [DW-1:0] xclk_data_reg_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next;
	reg [AW-1:0] wb_addr_reg_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next;
	reg wb_we_reg_next_next;
	reg xclk_we_reg_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next;
	reg wb_we_reg_next_next_next;
	reg xclk_we_reg_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next;
	reg wb_we_reg_next_next_next_next;
	reg xclk_we_reg_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] xclk_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] wb_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [AW-1:0] xclk_addr_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg wb_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg xclk_we_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [LGFIFO:0] wb_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [LGFIFO:0] xclk_fifo_count_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;

	reg [DW-1:0] wb_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW-1:0] xclk_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
	reg [DW/8-1:0] wb_sel_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_