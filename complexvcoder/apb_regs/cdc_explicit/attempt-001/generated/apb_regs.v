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

  // Internal signals
  logic [ApbAddrWidth-1:0] reg_addr;
  reg_data_t [NoApbRegs-1:0] reg_file;
  logic [NoApbRegs-1:0] read_data;
  logic [NoApbRegs-1:0] write_data;
  logic [NoApbRegs-1:0] write_en;
  logic [NoApbRegs-1:0] read_en;

  // Address generation
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_addr <= 0;
    end else begin
      reg_addr <= base_addr_i + (req_i ? (apb_addr_t) (req_i << AddrOffset) : 0);
    end
  end

  // Register file
  generate
    if (NoApbRegs > 0) begin
      reg reg_file [NoApbRegs-1:0];
      always_ff @(posedge pclk_i or negedge preset_ni) begin
        if (!preset_ni) begin
          for (int i = 0; i < NoApbRegs; i++) begin
            reg_file[i] <= reg_init_i[i * RegDataWidth +: RegDataWidth];
          end
        end else begin
          for (int i = 0; i < NoApbRegs; i++) begin
            if (write_en[i]) begin
              if (!ReadOnly[i]) begin
                reg_file[i] <= write_data[i];
              end
            end
          end
        end
      end
    end
  endgenerate

  // Read data
  assign read_data = reg_file[(reg_addr >> AddrOffset) % NoApbRegs];

  // Write data and enable
  assign write_data = req_i ? req_i[RegDataWidth-1:0] : 0;
  assign write_en = req_i && (reg_addr[AddrOffset-1:0] == 0);

  // Read enable
  assign read_en = req_i && (reg_addr[AddrOffset-1:0] == 0);

  // Response
  assign resp_o = req_i && (reg_addr[AddrOffset-1:0] == 0);

  // Output register data
  assign reg_q_o = read_data;

endmodule
