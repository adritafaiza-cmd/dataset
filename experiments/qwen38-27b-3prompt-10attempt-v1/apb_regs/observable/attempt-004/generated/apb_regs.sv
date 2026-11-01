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

  // Internal register storage
  reg_data_t [NoApbRegs-1:0] regs;

  // APB signals
  logic        paddr_valid;
  logic        penable;
  logic        pwrite;
  logic [ApbAddrWidth-1:0] paddr;
  logic [ApbDataWidth-1:0] pwdata;
  logic [ApbDataWidth-1:0] prdata;
  logic        pready;
  logic        pslverr;

  // Extract APB fields from req_i
  assign paddr_valid = req_i[0];
  assign penable     = req_i[1];
  assign pwrite      = req_i[2];
  assign paddr       = req_i[ApbAddrWidth+2:3];
  assign pwdata      = req_i[ApbAddrWidth+ApbDataWidth+2:ApbAddrWidth+3];

  // Generate response
  assign resp_o = {pslverr, pready, prdata[ApbDataWidth-1:0]};

  // Address decoding
  logic [ApbAddrWidth-1:0] offset_addr;
  logic [ApbAddrWidth-1:0] reg_index;
  logic                    addr_valid;

  assign offset_addr = paddr - base_addr_i;
  assign reg_index   = offset_addr / AddrOffset;
  assign addr_valid  = (reg_index < NoApbRegs) && (offset_addr % AddrOffset == 0);

  // Read data
  logic [RegDataWidth-1:0] read_data;
  assign read_data = regs[reg_index];

  // Truncate or extend to ApbDataWidth
  logic [ApbDataWidth-1:0] prdata_internal;
  generate
    if (RegDataWidth <= ApbDataWidth) begin : gen_trunc
      assign prdata_internal = read_data[ApbDataWidth-1:0];
    end else begin : gen_ext
      assign prdata_internal = { {(ApbDataWidth-RegDataWidth){1'b0}}, read_data };
    end
  endgenerate

  assign prdata = prdata_internal;

  // Write enable
  logic write_en;
  assign write_en = penable && pwrite && addr_valid;

  // Write data
  logic [RegDataWidth-1:0] write_data;
  generate
    if (ApbDataWidth <= RegDataWidth) begin : gen_w_trunc
      assign write_data = pwdata[RegDataWidth-1:0];
    end else begin : gen_w_ext
      assign write_data = { {(RegDataWidth-ApbDataWidth){1'b0}}, pwdata };
    end
  endgenerate

  // Register update logic
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        regs[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        if (!ReadOnly[reg_index]) begin
          regs[reg_index] <= write_data;
        end
      end
    end
  end

  // Output registers
  assign reg_q_o = regs;

  // APB ready and error
  assign pready  = 1'b1;
  assign pslverr = !addr_valid && penable;

endmodule
