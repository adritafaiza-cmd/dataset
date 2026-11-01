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
  // Since req_t is a type parameter, we need to access its fields
  // We'll use a localparam to define the expected structure

  // For APB, the request typically contains:
  // - psel: select
  // - penable: enable
  // - pwrite: write enable
  // - paddr: address
  // - pwdata: write data

  // We need to extract these from req_i. Since req_t is opaque,
  // we assume it has the standard APB fields. Let's define a local
  // unpacking.

  // Actually, since req_t is a type parameter, we can't directly access
  // its fields without knowing the structure. However, the problem states
  // "req_i / resp_o use the APB request and response types supplied by the testbench."
  // This implies req_t is a struct with APB fields.

  // Let's assume req_t has fields: psel, penable, pwrite, paddr, pwdata
  // and resp_t has fields: pready, pslverr, prdata

  // We'll create local signals to extract these
  wire psel;
  wire penable;
  wire pwrite;
  apb_addr_t paddr;
  reg_data_t pwdata;

  // Extract from req_i - this requires req_t to be a struct with these fields
  // Since we can't do this generically without knowing the exact structure,
  // we'll assume the standard APB struct layout

  // For a generic solution, we need to access the fields of req_t
  // Let's assume req_t is a struct with named fields

  // Actually, in SystemVerilog, if req_t is a struct type, we can access
  // its fields directly. Let's assume:
  // typedef struct packed {
  //   logic psel;
  //   logic penable;
  //   logic pwrite;
  //   apb_addr_t paddr;
  //   reg_data_t pwdata;
  // } apb_req_t;

  // So we can do:
  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite  = req_i.pwrite;
  assign paddr   = req_i.paddr;
  assign pwdata  = req_i.pwdata;

  // Response fields
  wire pready;
  wire pslverr;
  reg_data_t prdata;

  assign resp_o.pready = pready;
  assign resp_o.pslverr = pslverr;
  assign resp_o.prdata = prdata;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Address decoding
  // Calculate which register is being accessed
  // addr_offset in bits: AddrOffset * 8
  localparam int unsigned AddrOffsetBits = AddrOffset * 8;

  // Relative address from base
  apb_addr_t rel_addr;
  assign rel_addr = paddr - base_addr_i;

  // Register index
  logic [ApbAddrWidth-1:0] reg_idx;
  assign reg_idx = rel_addr >> $clog2(AddrOffsetBits);

  // Check if address is valid
  wire addr_valid = (reg_idx < NoApbRegs) && 
                    ((rel_addr & (AddrOffsetBits - 1)) == 0);

  // APB state machine
  localparam int unsigned ST_IDLE = 0;
  localparam int unsigned ST_SETUP = 1;
  localparam int unsigned ST_ACCESS = 2;

  logic [1:0] state_q, state_d;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni)
      state_q <= ST_IDLE;
    else
      state_q <= state_d;
  end

  always_comb begin
    state_d = state_q;
    pready = 1'b0;
    pslverr = 1'b0;
    prdata = '0;

    case (state_q)
      ST_IDLE: begin
        if (psel) begin
          state_d = ST_SETUP;
        end
      end
      ST_SETUP: begin
        if (psel && penable) begin
          state_d = ST_ACCESS;
        end else begin
          state_d = ST_IDLE;
        end
      end
      ST_ACCESS: begin
        pready = 1'b1;
        if (addr_valid) begin
          if (pwrite) begin
            // Write operation
            // Check if register is read-only
            if (ReadOnly[reg_idx]) begin
              pslverr = 1'b1;
            end
          end else begin
            // Read operation
            prdata = regs[reg_idx];
          end
        end else begin
          pslverr = 1'b1;
        end
        state_d = ST_IDLE;
      end
      default: begin
        state_d = ST_IDLE;
      end
    endcase
  end

  // Register update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        regs[i] <= reg_init_i[i];
      end
    end else begin
      if (state_q == ST_ACCESS && psel && penable && pwrite && addr_valid && !ReadOnly[reg_idx]) begin
        regs[reg_idx] <= pwdata;
      end
    end
  end

  // Drive output
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = regs[i];
    end
  end

endmodule
