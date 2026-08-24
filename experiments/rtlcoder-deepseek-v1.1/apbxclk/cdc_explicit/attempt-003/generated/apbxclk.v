module apbxclk #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32,
  parameter [0:0] OPT_REGISTERED = 1'b0
)(
  input  wire                         S_APB_PCLK,
  input  wire                         S_PRESETn,
  input  wire                         S_APB_PSEL,
  input  wire                         S_APB_PENABLE,
  output reg                          S_APB_PREADY,
  input  wire [C_APB_ADDR_WIDTH-1:0]  S_APB_PADDR,
  input  wire                         S_APB_PWRITE,
  input  wire [C_APB_DATA_WIDTH-1:0]  S_APB_PWDATA,
  input  wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
  input  wire [2:0]                   S_APB_PPROT,
  output wire [C_APB_DATA_WIDTH-1:0]  S_APB_PRDATA,
  output wire                         S_APB_PSLVERR,

  input  wire                         M_APB_PCLK,
  output reg                          M_PRESETn,
  output reg                          M_APB_PSEL,
  output reg                          M_APB_PENABLE,
  input  wire                         M_APB_PREADY,
  output wire [C_APB_ADDR_WIDTH-1:0]  M_APB_PADDR,
  output wire                         M_APB_PWRITE,
  output wire [C_APB_DATA_WIDTH-1:0]  M_APB_PWDATA,
  output wire [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
  output wire [2:0]                   M_APB_PPROT,
  input  wire [C_APB_DATA_WIDTH-1:0]  M_APB_PRDATA,
  input  wire                         M_APB_PSLVERR
);

reg [C_APB_ADDR_WIDTH-1:0] M_APB_PADDR_reg;
reg [C_APB_DATA_WIDTH-1:0] M_APB_PWDATA_reg;
reg [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB_reg;
reg [2:0] M_APB_PPROT_reg;

reg [C_APB_DATA_WIDTH-1:0] S_APB_PRDATA_reg;
reg S_APB_PSLVERR_reg;

reg [1:0] state;
parameter IDLE = 2'b00, SETUP = 2'b01, ACCESS = 2'b10;

always @(posedge S_APB_PCLK) begin
  if (!S_PRESETn) begin
    S_APB_PREADY <= 1'b0;
    M_PRESETn <= 1'b0;
    M_APB_PSEL <= 1'b0;
    M_APB_PENABLE <= 1'b0;
    M_APB_PADDR_reg <= 0;
    M_APB_PWDATA_reg <= 0;
    M_APB_PWSTRB_reg <= 0;
    M_APB_PPROT_reg <= 0;
    state <= IDLE;
  end else begin
    case (state)
      IDLE: begin
        if (S_APB_PSEL && S_APB_PENABLE) begin
          M_APB_PSEL <= 1'b1;
          M_APB_PENABLE <= 1'b1;
          M_APB_PADDR_reg <= S_APB_PADDR;
          M_APB_PWDATA_reg <= S_APB_PWDATA;
          M_APB_PWSTRB_reg <= S_APB_PWSTRB;
          M_APB_PPROT_reg <= S_APB_PPROT;
          state <= SETUP;
        end
      end
      SETUP: begin
        if (M_APB_PREADY) begin
          M_APB_PSEL <= 1'b0;
          M_APB_PENABLE <= 1'b0;
          state <= ACCESS;
        end
      end
      ACCESS: begin
        if (M_APB_PREADY) begin
          S_APB_PRDATA_reg <= M_APB_PRDATA;
          S_APB_PSLVERR_reg <= M_APB_PSLVERR;
          S_APB_PREADY <= 1'b1;
          state <= IDLE;
        end
      end
    endcase
  end
end

assign M_APB_PADDR = OPT_REGISTERED ? M_APB_PADDR_reg : S_APB_PADDR;
assign M_APB_PWDATA = OPT_REGISTERED ? M_APB_PWDATA_reg : S_APB_PWDATA;
assign M_APB_PWSTRB = OPT_REGISTERED ? M_APB_PWSTRB_reg : S_APB_PWSTRB;
assign M_APB_PPROT = OPT_REGISTERED ? M_APB_PPROT_reg : S_APB_PPROT;

assign S_APB_PRDATA = OPT_REGISTERED ? S_APB_PRDATA_reg : M_APB_PRDATA;
assign S_APB_PSLVERR = OPT_REGISTERED ? S_APB_PSLVERR_reg : M_APB_PSLVERR;

always @(posedge M_APB_PCLK) begin
  if (!S_PRESETn) begin
    M_PRESETn <= 1'b0;
  end else begin
    M_PRESETn <= 1'b1;
  end
end


endmodule
