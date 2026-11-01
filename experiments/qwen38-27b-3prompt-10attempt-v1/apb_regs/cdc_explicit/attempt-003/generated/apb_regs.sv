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

  // Extract APB fields from req_t
  // Assuming req_t has fields: psel, penable, pwrite, paddr, pwdata
  // We need to access these fields. Since req_t is a type parameter,
  // we assume it's a struct with these fields.
  
  // For APB protocol:
  // - PSEL: select
  // - PENABLE: enable
  // - PWRITE: write enable
  // - PADDR: address
  // - PWDATA: write data
  // - PREAD: read data (output)
  // - PREADY: ready (output)
  // - PSLVERR: slave error (output)
  
  // We'll assume req_t is a struct with fields:
  //   bit psel;
  //   bit penable;
  //   bit pwrite;
  //   apb_addr_t paddr;
  //   reg_data_t pwdata;
  
  // And resp_t is a struct with fields:
  //   bit pready;
  //   bit pslverr;
  //   reg_data_t prdata;

  // Local parameters
  localparam int unsigned ADDR_SHIFT = $clog2(AddrOffset);
  localparam int unsigned REG_INDEX_WIDTH = $clog2(NoApbRegs);
  
  // Decode address to register index
  // Address offset from base, divided by AddrOffset
  wire [ApbAddrWidth-1:0] addr_offset = req_i.paddr - base_addr_i;
  wire [REG_INDEX_WIDTH-1:0] reg_index = addr_offset[ADDR_SHIFT +: REG_INDEX_WIDTH];
  
  // Check if address is valid
  wire addr_valid = (reg_index < NoApbRegs) && 
                    (addr_offset[ADDR_SHIFT-1:0] == '0) &&
                    (addr_offset >= '0);
  
  // APB state machine
  // APB has two phases: SETUP and ACCESS
  // In SETUP: PSEL=1, PENABLE=0
  // In ACCESS: PSEL=1, PENABLE=1
  
  // We'll implement a simple APB slave that responds in the ACCESS phase
  
  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;
  
  // Initialize registers
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      // Handle writes
      if (req_i.psel && req_i.penable && req_i.pwrite && addr_valid) begin
        if (!ReadOnly[reg_index]) begin
          reg_q[reg_index] <= req_i.pwdata;
        end
      end
    end
  end
  
  // Drive register outputs
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_q[i];
    end
  end
  
  // APB response
  // PREADY is high when the slave is ready to complete the transfer
  // For a simple register file, we can respond in the same cycle as ACCESS
  // PSLVERR is high if the address is invalid
  
  always_comb begin
    resp_o.pready = 1'b1;
    resp_o.pslverr = !addr_valid;
    resp_o.prdata = addr_valid ? reg_q[reg_index] : '0;
  end

endmodule
