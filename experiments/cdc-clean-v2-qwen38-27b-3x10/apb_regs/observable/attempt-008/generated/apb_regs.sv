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

  // Extract APB signals from req_t
  wire        psel    = req_i.psel;
  wire        penable = req_i.penable;
  wire        pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;
  wire [ApbDataWidth/8-1:0] pstrb = req_i.pstrb;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = 8'h0; // Not used in this simplified interface

  // Address decoding
  wire [ApbAddrWidth-1:0] offset_addr = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_addr = offset_addr / AddrOffset;

  // Determine if address is within valid range
  wire addr_valid = (reg_index_addr < NoApbRegs);

  // Write enable: only during APB access (psel and penable) and write operation
  wire write_en = psel & penable & pwrite & addr_valid;

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Byte strobe mask for each register
  // We need to map the APB data width byte strobes to the register data width
  // Assuming RegDataWidth <= ApbDataWidth, and registers are aligned to byte boundaries

  // For each register, compute the byte strobe mask
  // The register data width may be less than ApbDataWidth
  // We assume registers are byte-aligned and the lower bytes of pwdata correspond to the register

  // Generate byte strobe mask for each register
  // If RegDataWidth is a multiple of 8, we can use the lower RegDataWidth/8 bytes of pstrb
  // Otherwise, we need to handle partial bytes, but typically RegDataWidth is a multiple of 8

  // Let's assume RegDataWidth is a multiple of 8 for simplicity
  // Number of bytes in register
  localparam int unsigned RegBytes = RegDataWidth / 8;
  localparam int unsigned ApbBytes = ApbDataWidth / 8;

  // For each register, the byte strobe mask is the lower RegBytes bytes of pstrb
  // (assuming the register is aligned to the lower bytes of the APB data bus)

  // Write logic
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_q[i] <= reg_init_i[i];
        else
          reg_q[i] <= '0;
      end
    end else begin
      if (write_en) begin
        for (int i = 0; i < NoApbRegs; i++) begin
          if (i == reg_index_addr) begin
            if (!ReadOnly[i]) begin
              // Apply byte strobes
              for (int b = 0; b < RegBytes; b++) begin
                if (b < ApbBytes && pstrb[b]) begin
                  reg_q[i][b*8 +: 8] <= pwdata[b*8 +: 8];
                end
              end
            end
          end
        end
      end
    end
  end

  // Output
  assign reg_q_o = reg_q;

endmodule
