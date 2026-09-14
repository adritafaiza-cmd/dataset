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

  localparam int unsigned RegAddrWidth = ApbAddrWidth - $clog2(AddrOffset);
  logic [RegAddrWidth-1:0] addr;
  logic [RegDataWidth-1:0] data_in;
  logic [RegDataWidth-1:0] data_out;
  logic reg_write;
  logic reg_read;
  logic [NoApbRegs-1:0] reg_file;

  // Decode the address
  assign addr = base_addr_i[ApbAddrWidth-1:$clog2(AddrOffset)];

  // Handle register read/write requests
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else begin
      if (req_i) begin
        if (addr < NoApbRegs) begin
          if (reg_write) begin
            if (!ReadOnly[addr]) begin
              reg_file[addr] <= data_in;
            end
          end else begin
            data_out <= reg_file[addr];
          end
        end
      end
    end
  end

  // Assign outputs
  assign reg_q_o = reg_file;
  assign resp_o = reg_write ? 1'b1 : 1'b0; // Simplified response for demonstration

  // Assign inputs
  assign data_in = req_i ? req_i.data : 0;
  assign reg_write = req_i ? req_i.write : 0;
  assign reg_read = req_i ? !req_i.write : 0;

endmodule
