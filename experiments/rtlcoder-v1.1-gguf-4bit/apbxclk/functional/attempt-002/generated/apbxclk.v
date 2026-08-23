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

  reg [C_APB_DATA_WIDTH-1:0] m_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] m_wstrb;
  reg [2:0] m_prot;
  reg m_write;
  reg m_enable;
  reg m_ready;
  reg m_presetn;

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (~S_PRESETn) begin
      S_APB_PREADY <= 1'b0;
      m_presetn <= 1'b1;
      m_write <= 1'b0;
      m_enable <= 1'b0;
      m_ready <= 1'b0;
    end else begin
      if (S_APB_PENABLE) begin
        if (S_APB_PWRITE) begin
          m_wdata <= S_APB_PWDATA;
          m_wstrb <= S_APB_PWSTRB;
          m_prot <= S_APB_PPROT;
          m_write <= 1'b1;
        end else begin
          m_write <= 1'b0;
        end

        m_enable <= 1'b1;
      end else begin
        m_enable <= 1'b0;
      end

      if (M_APB_PREADY) begin
        m_ready <= 1'b1;
      end else begin
        m_ready <= 1'b0;
      end

      if (M_APB_PSEL) begin
        S_APB_PREADY <= m_ready;
      end
    end
  end

  always @(posedge M_APB_PCLK or negedge m_presetn) begin
    if (~m_presetn) begin
      M_PRESETn <= 1'b1;
      M_APB_PSEL <= 1'b0;
      M_APB_PENABLE <= 1'b0;
      M_APB_PWRITE <= 1'b0;
      M_APB_PADDR <= 0;
      M_APB_PWDATA <= 0;
      M_APB_PWSTRB <= 0;
      M_APB_PPROT <= 0;
      M_APB_PRDATA <= 0;
      M_APB_PSLVERR <= 1'b0;
    end else begin
      if (M_APB_PREADY) begin
        M_APB_PSEL <= S_APB_PSEL;
        M_APB_PENABLE <= S_APB_PENABLE;
        M_APB_PWRITE <= S_APB_PWRITE;
        M_APB_PADDR <= S_APB_PADDR;
        M_APB_PWDATA <= m_wdata;
        M_APB_PWSTRB <= m_wstrb;
        M_APB_PPROT <= m_prot;
        M_APB_PRDATA <= S_APB_PRDATA;
        M_APB_PSLVERR <= S_APB_PSLVERR;
      end
    end
  end


endmodule
