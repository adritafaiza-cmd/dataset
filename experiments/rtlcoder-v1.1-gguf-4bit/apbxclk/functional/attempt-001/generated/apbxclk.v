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

  // Internal signals
  reg [C_APB_ADDR_WIDTH-1:0] m_addr;
  reg [C_APB_DATA_WIDTH-1:0] m_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] m_wstrb;
  reg [2:0] m_prot;
  reg m_write;
  reg m_enable;
  reg m_ready;

  // Initialize internal signals
  initial begin
    m_addr = 0;
    m_wdata = 0;
    m_wstrb = 0;
    m_prot = 0;
    m_write = 0;
    m_enable = 0;
    m_ready = 0;
  end

  // Synchronize source and destination clocks
  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (~S_PRESETn) begin
      S_APB_PREADY <= 0;
      m_addr <= 0;
      m_wdata <= 0;
      m_wstrb <= 0;
      m_prot <= 0;
      m_write <= 0;
      m_enable <= 0;
      m_ready <= 0;
    end else begin
      // Source domain
      if (S_APB_PENABLE) begin
        if (S_APB_PWRITE) begin
          m_write <= 1;
          m_addr <= S_APB_PADDR;
          m_wdata <= S_APB_PWDATA;
          m_wstrb <= S_APB_PWSTRB;
          m_prot <= S_APB_PPROT;
        end else begin
          m_write <= 0;
          m_addr <= S_APB_PADDR;
          m_wstrb <= S_APB_PWSTRB;
          m_prot <= S_APB_PPROT;
        end
        m_enable <= 1;
      end else begin
        m_enable <= 0;
      end

      // Destination domain
      if (M_APB_PCLK) begin
        if (M_APB_PREADY) begin
          m_ready <= 1;
        end else begin
          m_ready <= 0;
        end
      end
    end
  end

  // Output signals
  assign S_APB_PREADY = m_ready;
  assign M_PRESETn = S_PRESETn;
  assign M_APB_PSEL = S_APB_PSEL;
  assign M_APB_PENABLE = S_APB_PENABLE;
  assign M_APB_PADDR = m_addr;
  assign M_APB_PWRITE = m_write;
  assign M_APB_PWDATA = m_wdata;
  assign M_APB_PWSTRB = m_wstrb;
  assign M_APB_PPROT = m_prot;
  assign S_APB_PSLVERR = M_APB_PSLVERR;
  assign S_APB_PRDATA = M_APB_PRDATA;


endmodule
