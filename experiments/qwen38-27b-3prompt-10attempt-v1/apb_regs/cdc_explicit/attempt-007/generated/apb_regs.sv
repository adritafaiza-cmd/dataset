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
  localparam int unsigned ADDR_SHIFT = (AddrOffset == 1) ? 0 : $clog2(AddrOffset);
  localparam int unsigned REG_INDEX_WIDTH = (NoApbRegs > 1) ? $clog2(NoApbRegs) : 1;
  localparam int unsigned DATA_WIDTH = (RegDataWidth > ApbDataWidth) ? RegDataWidth : ApbDataWidth;

  // Internal signals
  logic [REG_INDEX_WIDTH-1:0] reg_index;
  logic                       reg_index_valid;
  logic                       is_write;
  logic                       is_read;
  logic [DATA_WIDTH-1:0]      write_data;
  logic [DATA_WIDTH-1:0]      read_data;
  logic [DATA_WIDTH-1:0]      reg_data_internal [NoApbRegs-1:0];

  // Extract fields from APB request
  // Assuming standard APB-like structure:
  // req_i.psel, req_i.penable, req_i.pwrite, req_i.paddr, req_i.pwdata
  // Since req_t is a type parameter, we need to access its fields.
  // For a generic implementation, we'll assume the request type has:
  // - psel: select signal
  // - penable: enable signal  
  // - pwrite: write enable
  // - paddr: address
  // - pwdata: write data

  // Decode address to register index
  assign reg_index = (req_i.paddr - base_addr_i) >> ADDR_SHIFT;
  assign reg_index_valid = (reg_index < NoApbRegs);

  // Determine read/write
  assign is_write = req_i.psel & req_i.penable & req_i.pwrite & reg_index_valid;
  assign is_read  = req_i.psel & req_i.penable & ~req_i.pwrite & reg_index_valid;

  // Prepare write data (truncate or extend to DATA_WIDTH)
  generate
    if (DATA_WIDTH >= ApbDataWidth) begin : gen_write_data
      assign write_data = {{(DATA_WIDTH - ApbDataWidth){1'b0}}, req_i.pwdata};
    end else begin : gen_write_data
      assign write_data = req_i.pwdata[DATA_WIDTH-1:0];
    end
  endgenerate

  // Register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_data_internal[i] <= reg_init_i[i];
      end
    end else begin
      if (is_write) begin
        if (!ReadOnly[reg_index]) begin
          reg_data_internal[reg_index] <= write_data;
        end
      end
    end
  end

  // Read data
  assign read_data = reg_data_internal[reg_index];

  // Drive output registers
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_data_internal[i];
    end
  end

  // Response
  // Assuming resp_t has a status field, e.g., resp_o.pready or resp_o.pslverr
  // For simplicity, we'll set pready high when the transfer is complete
  // and pslverr low (no error)
  assign resp_o = '0;
  // Set pready if the request is valid
  if (req_i.psel & req_i.penable) begin
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end else begin
    resp_o.pready = 1'b0;
    resp_o.pslverr = 1'b0;
  end

endmodule
