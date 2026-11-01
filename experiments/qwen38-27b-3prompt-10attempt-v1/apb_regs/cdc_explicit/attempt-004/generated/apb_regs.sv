module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type apb_addr_t                  = logic[ApbAddrWidth-1:0],
  parameter type reg_data_t                  = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Local parameters
  localparam int unsigned ADDR_SHIFT = $clog2(AddrOffset);
  localparam int unsigned REG_INDEX_WIDTH = (NoApbRegs > 1) ? $clog2(NoApbRegs) : 1;

  // APB signal extraction
  // Assuming standard APB3/4 signals:
  // req_i contains: psel, penable, pwrite, paddr, pwdata, pstrb
  // resp_o contains: pready, prdata, pslverr

  // Extract APB signals from req_t
  wire psel;
  wire penable;
  wire pwrite;
  wire [ApbAddrWidth-1:0] paddr;
  wire [ApbDataWidth-1:0] pwdata;
  wire [ApbDataWidth/8-1:0] pstrb;

  assign psel    = req_t.psel;
  assign penable = req_t.penable;
  assign pwrite  = req_t.pwrite;
  assign paddr   = req_t.paddr;
  assign pwdata  = req_t.pwdata;
  assign pstrb   = req_t.pstrb;

  // Response signals
  wire pready;
  wire [ApbDataWidth-1:0] prdata;
  wire pslverr;

  assign resp_t.pready   = pready;
  assign resp_t.prdata   = prdata;
  assign resp_t.pslverr  = pslverr;

  // Address decoding
  // Calculate register index from address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  wire [REG_INDEX_WIDTH-1:0] reg_index = (NoApbRegs > 1) ? addr_offset[ADDR_SHIFT +: REG_INDEX_WIDTH] : 1'b0;
  wire [ADDR_SHIFT-1:0] byte_offset = (ADDR_SHIFT > 0) ? addr_offset[ADDR_SHIFT-1:0] : 1'b0;

  // Valid register index check
  wire reg_index_valid = (NoApbRegs > 1) ? (reg_index < NoApbRegs) : 1'b1;

  // APB state machine
  localparam APB_IDLE = 1'b0;
  localparam APB_SETUP = 1'b1;

  reg apb_state;
  wire apb_idle = (apb_state == APB_IDLE);
  wire apb_setup = (apb_state == APB_SETUP);

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni)
      apb_state <= APB_IDLE;
    else begin
      case (apb_state)
        APB_IDLE: begin
          if (psel)
            apb_state <= APB_SETUP;
        end
        APB_SETUP: begin
          if (psel && penable)
            apb_state <= APB_IDLE;
        end
        default: apb_state <= APB_IDLE;
      endcase
    end
  end

  // Pready is always high (no wait states)
  assign pready = 1'b1;

  // Pslverr: error if address is out of range
  assign pslverr = (psel && penable && !reg_index_valid) ? 1'b1 : 1'b0;

  // Read data mux
  wire [RegDataWidth-1:0] read_data;
  assign read_data = (NoApbRegs > 1) ? reg_q_o[reg_index] : reg_q_o[0];

  // Truncate or extend read data to ApbDataWidth
  wire [ApbDataWidth-1:0] prdata_internal;
  generate
    if (RegDataWidth <= ApbDataWidth) begin : gen_read_extend
      assign prdata_internal = {{(ApbDataWidth - RegDataWidth){1'b0}}, read_data};
    end else begin : gen_read_truncate
      assign prdata_internal = read_data[ApbDataWidth-1:0];
    end
  endgenerate

  assign prdata = prdata_internal;

  // Write enable and data
  wire write_enable = psel && penable && pwrite && reg_index_valid;

  // Write data with byte strobe
  wire [RegDataWidth-1:0] write_data;
  wire [RegDataWidth-1:0] write_mask;

  generate
    if (RegDataWidth <= ApbDataWidth) begin : gen_write_extend
      assign write_data = {{(RegDataWidth - ApbDataWidth){1'b0}}, pwdata};
      assign write_mask = {{(RegDataWidth - ApbDataWidth){1'b0}}, {pstrb[ApbDataWidth/8-1:0]}};
    end else begin : gen_write_truncate
      assign write_data = pwdata[RegDataWidth-1:0];
      assign write_mask = {pstrb[ApbDataWidth/8-1:0]};
    end
  endgenerate

  // Expand byte strobe to bit mask
  wire [RegDataWidth-1:0] bit_mask;
  genvar i;
  generate
    for (i = 0; i < RegDataWidth; i = i + 1) begin : gen_bit_mask
      assign bit_mask[i] = write_mask[i/8];
    end
  endgenerate

  // Register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int unsigned i = 0; i < NoApbRegs; i = i + 1)
        reg_q_o[i] <= reg_init_i[i];
    end else begin
      for (int unsigned i = 0; i < NoApbRegs; i = i + 1) begin
        if (write_enable && (reg_index == i)) begin
          // Apply write mask, respect read-only bits
          for (int unsigned b = 0; b < RegDataWidth; b = b + 1) begin
            if (bit_mask[b] && !ReadOnly[i])
              reg_q_o[i][b] <= write_data[b];
          end
        end
      end
    end
  end

endmodule
