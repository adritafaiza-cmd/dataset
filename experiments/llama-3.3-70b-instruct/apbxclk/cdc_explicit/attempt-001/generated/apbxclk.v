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
  output reg [C_APB_DATA_WIDTH-1:0]   S_APB_PRDATA,
  output reg                          S_APB_PSLVERR,

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

  reg [C_APB_ADDR_WIDTH-1:0]  s_addr;
  reg                         s_write;
  reg [C_APB_DATA_WIDTH-1:0]  s_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] s_wstrb;
  reg [2:0]                   s_prot;
  reg                         s_valid;
  reg                         m_valid;
  reg                         m_ready;
  reg [C_APB_DATA_WIDTH-1:0]  m_rdata;
  reg                         m_slverr;

  assign M_PRESETn = S_PRESETn;

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      s_valid <= 1'b0;
      s_addr <= {C_APB_ADDR_WIDTH{1'b0}};
      s_write <= 1'b0;
      s_wdata <= {C_APB_DATA_WIDTH{1'b0}};
      s_wstrb <= {C_APB_DATA_WIDTH/8{1'b0}};
      s_prot <= {3{1'b0}};
    end else if (S_APB_PSEL && !S_APB_PENABLE) begin
      s_valid <= 1'b1;
      s_addr <= S_APB_PADDR;
      s_write <= S_APB_PWRITE;
      s_wdata <= S_APB_PWDATA;
      s_wstrb <= S_APB_PWSTRB;
      s_prot <= S_APB_PPROT;
    end
  end

  always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
    if (!M_PRESETn) begin
      m_valid <= 1'b0;
      M_APB_PSEL <= 1'b0;
      M_APB_PENABLE <= 1'b0;
      M_APB_PADDR <= {C_APB_ADDR_WIDTH{1'b0}};
      M_APB_PWRITE <= 1'b0;
      M_APB_PWDATA <= {C_APB_DATA_WIDTH{1'b0}};
      M_APB_PWSTRB <= {C_APB_DATA_WIDTH/8{1'b0}};
      M_APB_PPROT <= {3{1'b0}};
    end else if (s_valid && !m_valid) begin
      m_valid <= 1'b1;
      M_APB_PSEL <= 1'b1;
      M_APB_PADDR <= s_addr;
      M_APB_PWRITE <= s_write;
      M_APB_PWDATA <= s_wdata;
      M_APB_PWSTRB <= s_wstrb;
      M_APB_PPROT <= s_prot;
    end else if (m_valid && M_APB_PREADY) begin
      m_valid <= 1'b0;
      M_APB_PSEL <= 1'b0;
      M_APB_PENABLE <= 1'b0;
    end
  end

  always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
    if (!M_PRESETn) begin
      m_ready <= 1'b0;
      m_rdata <= {C_APB_DATA_WIDTH{1'b0}};
      m_slverr <= 1'b0;
    end else if (m_valid && M_APB_PREADY) begin
      m_ready <= 1'b1;
      m_rdata <= M_APB_PRDATA;
      m_slverr <= M_APB_PSLVERR;
    end else if (m_ready && !m_valid) begin
      m_ready <= 1'b0;
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      S_APB_PREADY <= 1'b0;
      S_APB_PRDATA <= {C_APB_DATA_WIDTH{1'b0}};
      S_APB_PSLVERR <= 1'b0;
    end else if (m_ready) begin
      S_APB_PREADY <= 1'b1;
      S_APB_PRDATA <= m_rdata;
      S_APB_PSLVERR <= m_slverr;
      s_valid <= 1'b0;
    end else if (!m_ready && S_APB_PENABLE) begin
      S_APB_PREADY <= 1'b0;
    end
  end

  always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
    if (!M_PRESETn) begin
      M_APB_PENABLE <= 1'b0;
    end else if (m_valid && !M_APB_PENABLE) begin
      M_APB_PENABLE <= 1'b1;
    end else if (m_valid && M_APB_PREADY) begin
      M_APB_PENABLE <= 1'b0;
    end
  end

  if (OPT_REGISTERED == 1'b1) begin
    reg [C_APB_DATA_WIDTH-1:0]  m_rdata_reg;
    reg                         m_slverr_reg;

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
      if (!M_PRESETn) begin
        m_rdata_reg <= {C_APB_DATA_WIDTH{1'b0}};
        m_slverr_reg <= 1'b0;
      end else if (m_valid && M_APB_PREADY) begin
        m_rdata_reg <= M_APB_PRDATA;
        m_slverr_reg <= M_APB_PSLVERR;
      end
    end

    assign m_rdata = m_rdata_reg;
    assign m_slverr = m_slverr_reg;
  end

endmodule
