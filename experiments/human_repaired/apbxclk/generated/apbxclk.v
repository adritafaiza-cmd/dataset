// Functionally correct APB clock bridge with intentional CDC unsafety:
// request/ack and payload cross clocks with no synchronizer and no reset sync.
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
  output reg [C_APB_ADDR_WIDTH-1:0]   M_APB_PADDR,
  output reg                          M_APB_PWRITE,
  output reg [C_APB_DATA_WIDTH-1:0]   M_APB_PWDATA,
  output reg [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
  output reg [2:0]                    M_APB_PPROT,
  input  wire [C_APB_DATA_WIDTH-1:0]  M_APB_PRDATA,
  input  wire                         M_APB_PSLVERR
);

  reg                         s_req;
  reg                         m_ack;
  reg [C_APB_DATA_WIDTH-1:0]  s_prdata;
  reg                         s_pslverr;
  reg [C_APB_DATA_WIDTH-1:0]  m_prdata;
  reg                         m_pslverr;

  assign S_APB_PRDATA  = s_prdata;
  assign S_APB_PSLVERR = s_pslverr;

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      s_req        <= 1'b0;
      S_APB_PREADY <= 1'b0;
      s_prdata     <= {C_APB_DATA_WIDTH{1'b0}};
      s_pslverr    <= 1'b0;
    end else begin
      S_APB_PREADY <= 1'b0;
      if (S_APB_PSEL && !S_APB_PENABLE && !s_req && !m_ack) begin
        M_APB_PADDR  <= S_APB_PADDR;
        M_APB_PWRITE <= S_APB_PWRITE;
        M_APB_PWDATA <= S_APB_PWDATA;
        M_APB_PWSTRB <= S_APB_PWSTRB;
        M_APB_PPROT  <= S_APB_PPROT;
        s_req        <= 1'b1;
      end else if (s_req && m_ack && S_APB_PSEL && S_APB_PENABLE) begin
        s_prdata     <= m_prdata;
        s_pslverr    <= m_pslverr;
        S_APB_PREADY <= 1'b1;
        s_req        <= 1'b0;
      end
    end
  end

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      M_PRESETn    <= 1'b0;
      M_APB_PSEL   <= 1'b0;
      M_APB_PENABLE<= 1'b0;
      m_ack        <= 1'b0;
      m_prdata     <= {C_APB_DATA_WIDTH{1'b0}};
      m_pslverr    <= 1'b0;
    end else begin
      M_PRESETn <= 1'b1;
      if (!s_req)
        m_ack <= 1'b0;
      else if (s_req && !m_ack && !M_APB_PSEL && !M_APB_PENABLE) begin
        M_APB_PSEL    <= 1'b1;
        M_APB_PENABLE <= 1'b0;
      end else if (M_APB_PSEL && !M_APB_PENABLE) begin
        M_APB_PENABLE <= 1'b1;
      end else if (M_APB_PSEL && M_APB_PENABLE && M_APB_PREADY) begin
        m_prdata      <= M_APB_PRDATA;
        m_pslverr     <= M_APB_PSLVERR;
        M_APB_PSEL    <= 1'b0;
        M_APB_PENABLE <= 1'b0;
        m_ack         <= 1'b1;
      end
    end
  end

  // OPT_REGISTERED is unused: payload already lives in registers.
  wire unused_opt = OPT_REGISTERED;

endmodule
