module apbxclk #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32,
  parameter [0:0] OPT_REGISTERED = 1'b0
)(
  input  wire                          S_APB_PCLK,
  input  wire                          S_PRESETn,
  input  wire                          S_APB_PSEL,
  input  wire                          S_APB_PENABLE,
  output reg                           S_APB_PREADY,
  input  wire [C_APB_ADDR_WIDTH-1:0]   S_APB_PADDR,
  input  wire                          S_APB_PWRITE,
  input  wire [C_APB_DATA_WIDTH-1:0]   S_APB_PWDATA,
  input  wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
  input  wire [2:0]                    S_APB_PPROT,
  output wire [C_APB_DATA_WIDTH-1:0]   S_APB_PRDATA,
  output wire                          S_APB_PSLVERR,

  input  wire                          M_APB_PCLK,
  output reg                           M_PRESETn,
  output reg                           M_APB_PSEL,
  output reg                           M_APB_PENABLE,
  input  wire                          M_APB_PREADY,
  output wire [C_APB_ADDR_WIDTH-1:0]   M_APB_PADDR,
  output wire                          M_APB_PWRITE,
  output wire [C_APB_DATA_WIDTH-1:0]   M_APB_PWDATA,
  output wire [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
  output wire [2:0]                    M_APB_PPROT,
  input  wire [C_APB_DATA_WIDTH-1:0]   M_APB_PRDATA,
  input  wire                          M_APB_PSLVERR
);

  localparam [1:0] M_IDLE   = 2'd0;
  localparam [1:0] M_SETUP  = 2'd1;
  localparam [1:0] M_ACCESS = 2'd2;

  reg [1:0] m_reset_sync;

  reg                          s_req_toggle;
  reg                          s_busy;
  reg                          s_response_pending;
  reg [C_APB_ADDR_WIDTH-1:0]   s_req_addr;
  reg                          s_req_write;
  reg [C_APB_DATA_WIDTH-1:0]   s_req_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] s_req_wstrb;
  reg [2:0]                    s_req_prot;

  reg m_rsp_sync1;
  reg m_rsp_sync2;
  reg s_rsp_seen;

  reg [C_APB_DATA_WIDTH-1:0] s_rsp_data;
  reg                        s_rsp_error;

  reg m_req_sync1;
  reg m_req_sync2;
  reg m_req_seen;

  reg [1:0] m_state;

  reg [C_APB_ADDR_WIDTH-1:0]   m_req_addr;
  reg                          m_req_write;
  reg [C_APB_DATA_WIDTH-1:0]   m_req_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] m_req_wstrb;
  reg [2:0]                    m_req_prot;

  reg [C_APB_DATA_WIDTH-1:0] m_rsp_data;
  reg                        m_rsp_error;
  reg                        m_rsp_toggle;

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_reset_sync <= 2'b00;
      M_PRESETn    <= 1'b0;
    end else begin
      m_reset_sync[0] <= 1'b1;
      m_reset_sync[1] <= m_reset_sync[0];
      M_PRESETn       <= m_reset_sync[1];
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      S_APB_PREADY       <= 1'b0;
      s_req_toggle       <= 1'b0;
      s_busy             <= 1'b0;
      s_response_pending <= 1'b0;

      s_req_addr  <= {C_APB_ADDR_WIDTH{1'b0}};
      s_req_write <= 1'b0;
      s_req_wdata <= {C_APB_DATA_WIDTH{1'b0}};
      s_req_wstrb <= {(C_APB_DATA_WIDTH/8){1'b0}};
      s_req_prot  <= 3'b000;

      m_rsp_sync1 <= 1'b0;
      m_rsp_sync2 <= 1'b0;
      s_rsp_seen  <= 1'b0;
      s_rsp_data  <= {C_APB_DATA_WIDTH{1'b0}};
      s_rsp_error <= 1'b0;
    end else begin
      S_APB_PREADY <= 1'b0;

      m_rsp_sync1 <= m_rsp_toggle;
      m_rsp_sync2 <= m_rsp_sync1;

      if (m_rsp_sync2 != s_rsp_seen) begin
        s_rsp_seen  <= m_rsp_sync2;
        s_rsp_data  <= m_rsp_data;
        s_rsp_error <= m_rsp_error;

        if (s_busy)
          s_response_pending <= 1'b1;
      end

      if (s_response_pending &&
          S_APB_PSEL && S_APB_PENABLE) begin
        S_APB_PREADY       <= 1'b1;
        s_busy             <= 1'b0;
        s_response_pending <= 1'b0;
      end

      if (!s_busy && !s_response_pending &&
          S_APB_PSEL && !S_APB_PENABLE) begin
        s_req_addr   <= S_APB_PADDR;
        s_req_write  <= S_APB_PWRITE;
        s_req_wdata  <= S_APB_PWDATA;
        s_req_wstrb  <= S_APB_PWSTRB;
        s_req_prot   <= S_APB_PPROT;
        s_req_toggle <= ~s_req_toggle;
        s_busy       <= 1'b1;
      end
    end
  end

  always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
    if (!M_PRESETn) begin
      m_req_sync1 <= 1'b0;
      m_req_sync2 <= 1'b0;
      m_req_seen  <= 1'b0;

      m_state       <= M_IDLE;
      M_APB_PSEL    <= 1'b0;
      M_APB_PENABLE <= 1'b0;

      m_req_addr  <= {C_APB_ADDR_WIDTH{1'b0}};
      m_req_write <= 1'b0;
      m_req_wdata <= {C_APB_DATA_WIDTH{1'b0}};
      m_req_wstrb <= {(C_APB_DATA_WIDTH/8){1'b0}};
      m_req_prot  <= 3'b000;

      m_rsp_data   <= {C_APB_DATA_WIDTH{1'b0}};
      m_rsp_error  <= 1'b0;
      m_rsp_toggle <= 1'b0;
    end else begin
      m_req_sync1 <= s_req_toggle;
      m_req_sync2 <= m_req_sync1;

      case (m_state)
        M_IDLE: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;

          if (m_req_sync2 != m_req_seen) begin
            m_req_seen  <= m_req_sync2;
            m_req_addr  <= s_req_addr;
            m_req_write <= s_req_write;
            m_req_wdata <= s_req_wdata;
            m_req_wstrb <= s_req_wstrb;
            m_req_prot  <= s_req_prot;

            M_APB_PSEL    <= 1'b1;
            M_APB_PENABLE <= 1'b0;
            m_state       <= M_SETUP;
          end
        end

        M_SETUP: begin
          M_APB_PSEL    <= 1'b1;
          M_APB_PENABLE <= 1'b1;
          m_state       <= M_ACCESS;
        end

        M_ACCESS: begin
          M_APB_PSEL    <= 1'b1;
          M_APB_PENABLE <= 1'b1;

          if (M_APB_PREADY) begin
            m_rsp_data   <= M_APB_PRDATA;
            m_rsp_error  <= M_APB_PSLVERR;
            m_rsp_toggle <= ~m_rsp_toggle;

            M_APB_PSEL    <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_state       <= M_IDLE;
          end
        end

        default: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;
          m_state       <= M_IDLE;
        end
      endcase
    end
  end

  generate
    if (OPT_REGISTERED == 1'b1) begin : g_registered
      assign M_APB_PADDR =
          M_PRESETn ? m_req_addr : {C_APB_ADDR_WIDTH{1'b0}};
      assign M_APB_PWRITE =
          M_PRESETn ? m_req_write : 1'b0;
      assign M_APB_PWDATA =
          M_PRESETn ? m_req_wdata : {C_APB_DATA_WIDTH{1'b0}};
      assign M_APB_PWSTRB =
          M_PRESETn ? m_req_wstrb : {(C_APB_DATA_WIDTH/8){1'b0}};
      assign M_APB_PPROT =
          M_PRESETn ? m_req_prot : 3'b000;

      assign S_APB_PRDATA =
          S_PRESETn ? s_rsp_data : {C_APB_DATA_WIDTH{1'b0}};
      assign S_APB_PSLVERR =
          S_PRESETn ? s_rsp_error : 1'b0;
    end else begin : g_unregistered
      assign M_APB_PADDR =
          M_PRESETn ? s_req_addr : {C_APB_ADDR_WIDTH{1'b0}};
      assign M_APB_PWRITE =
          M_PRESETn ? s_req_write : 1'b0;
      assign M_APB_PWDATA =
          M_PRESETn ? s_req_wdata : {C_APB_DATA_WIDTH{1'b0}};
      assign M_APB_PWSTRB =
          M_PRESETn ? s_req_wstrb : {(C_APB_DATA_WIDTH/8){1'b0}};
      assign M_APB_PPROT =
          M_PRESETn ? s_req_prot : 3'b000;

      assign S_APB_PRDATA =
          S_PRESETn ? m_rsp_data : {C_APB_DATA_WIDTH{1'b0}};
      assign S_APB_PSLVERR =
          S_PRESETn ? m_rsp_error : 1'b0;
    end
  endgenerate

endmodule
