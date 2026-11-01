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
  localparam int unsigned DATA_WIDTH = RegDataWidth;

  // APB signal extraction from req_t
  // Assuming req_t has fields: psel, penable, pwrite, paddr, pwdata
  // We'll use a typedef or direct field access. Since req_t is a type parameter,
  // we assume it's a struct with standard APB fields.
  // For safety, we'll define local signals and extract based on common APB struct layout.
  
  // Since req_t is a type parameter, we need to access its fields.
  // Common APB request struct fields: psel, penable, pwrite, paddr, pwdata
  // We'll assume the struct has these fields.
  
  wire        psel    = req_i.psel;
  wire        penable = req_i.penable;
  wire        pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;

  // Response signals
  wire        pready = 1'b1; // Always ready
  wire        pslverr = 1'b0; // No error
  wire [ApbDataWidth-1:0] prdata = '0;

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Address decoding
  wire [ApbAddrWidth-1:0] offset_addr = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_addr = offset_addr >> ADDR_SHIFT;
  
  // Check if address is within range
  wire addr_valid = (reg_index_addr < NoApbRegs);
  
  // Extract register index
  wire [REG_INDEX_WIDTH-1:0] reg_index = reg_index_addr[REG_INDEX_WIDTH-1:0];

  // Write enable
  wire write_en = psel & penable & pwrite & addr_valid;

  // Read data
  wire [DATA_WIDTH-1:0] read_data = reg_q[reg_index];

  // Truncate or extend data to ApbDataWidth
  wire [ApbDataWidth-1:0] prdata_out;
  generate
    if (ApbDataWidth >= DATA_WIDTH) begin : gen_data_extend
      assign prdata_out = {{(ApbDataWidth-DATA_WIDTH){1'b0}}, read_data};
    end else begin : gen_data_truncate
      assign prdata_out = read_data[ApbDataWidth-1:0];
    end
  endgenerate

  // Write data
  wire [DATA_WIDTH-1:0] write_data;
  generate
    if (ApbDataWidth >= DATA_WIDTH) begin : gen_write_extend
      assign write_data = pwdata[DATA_WIDTH-1:0];
    end else begin : gen_write_truncate
      assign write_data = {{(DATA_WIDTH-ApbDataWidth){1'b0}}, pwdata};
    end
  endgenerate

  // Register update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        if (!ReadOnly[reg_index]) begin
          reg_q[reg_index] <= write_data;
        end
      end
    end
  end

  // Drive output
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_q[i];
    end
  end

  // Response
  assign resp_o.pready = pready;
  assign resp_o.pslverr = pslverr;
  assign resp_o.prdata = prdata_out;

endmodule
