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

  localparam [1:0] M_IDLE   = 2'b00;
  localparam [1:0] M_SETUP  = 2'b01;
  localparam [1:0] M_ACCESS = 2'b10;

  reg [1:0] m_reset_sync;

  reg req_toggle;
  reg source_busy;

  reg [C_APB_ADDR_WIDTH-1:0]   s_req_addr;
  reg                          s_req_write;
  reg [C_APB_DATA_WIDTH-1:0]   s_req_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] s_req_wstrb;
  reg [2:0]                    s_req_prot;

  reg req_sync_1;
  reg req_sync_2;
  reg req_seen;

  reg [C_APB_ADDR_WIDTH-1:0]   m_req_addr;
  reg                          m_req_write;
  reg [C_APB_DATA_WIDTH-1:0]   m_req_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] m_req_wstrb;
  reg [2:0]                    m_req_prot;

  reg [1:0] m_state;

  reg [C_APB_DATA_WIDTH-1:0] m_resp_data;
  reg                        m_resp_error;
  reg                        resp_toggle;

  reg resp_sync_1;
  reg resp_sync_2;

  reg [C_APB_DATA_WIDTH-1:0] s_resp_data;
  reg                        s_resp_error;

  generate
    if (OPT_REGISTERED == 1'b1) begin : g_registered
      assign M_APB_PADDR   = m_req_addr;
      assign M_APB_PWRITE  = m_req_write;
      assign M_APB_PWDATA  = m_req_wdata;
      assign M_APB_PWSTRB  = m_req_wstrb;
      assign M_APB_PPROT   = m_req_prot;
      assign S_APB_PRDATA  = s_resp_data;
      assign S_APB_PSLVERR = s_resp_error;
    end
    else begin : g_unregistered
      assign M_APB_PADDR   = S_APB_PADDR;
      assign M_APB_PWRITE  = S_APB_PWRITE;
      assign M_APB_PWDATA  = S_APB_PWDATA;
      assign M_APB_PWSTRB  = S_APB_PWSTRB;
      assign M_APB_PPROT   = S_APB_PPROT;
      assign S_APB_PRDATA  = m_resp_data;
      assign S_APB_PSLVERR = m_resp_error;
    end
  endgenerate

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_reset_sync <= 2'b00;
      M_PRESETn    <= 1'b0;
    end
    else begin
      m_reset_sync[0] <= 1'b1;
      m_reset_sync[1] <= m_reset_sync[0];
      M_PRESETn       <= m_reset_sync[1];
    end
  end

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      req_sync_1 <= 1'b0;
      req_sync_2 <= 1'b0;
    end
    else if (!M_PRESETn) begin
      req_sync_1 <= 1'b0;
      req_sync_2 <= 1'b0;
    end
    else begin
      req_sync_1 <= req_toggle;
      req_sync_2 <= req_sync_1;
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      resp_sync_1 <= 1'b0;
      resp_sync_2 <= 1'b0;
    end
    else begin
      resp_sync_1 <= resp_toggle;
      resp_sync_2 <= resp_sync_1;
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      req_toggle  <= 1'b0;
      source_busy <= 1'b0;
      S_APB_PREADY <= 1'b0;

      s_req_addr  <= {C_APB_ADDR_WIDTH{1'b0}};
      s_req_write <= 1'b0;
      s_req_wdata <= {C_APB_DATA_WIDTH{1'b0}};
      s_req_wstrb <= {(C_APB_DATA_WIDTH/8){1'b0}};
      s_req_prot  <= 3'b000;

      s_resp_data  <= {C_APB_DATA_WIDTH{1'b0}};
      s_resp_error <= 1'b0;
    end
    else begin
      S_APB_PREADY <= 1'b0;

      if (!source_busy) begin
        if (S_APB_PSEL && S_APB_PENABLE) begin
          s_req_addr  <= S_APB_PADDR;
          s_req_write <= S_APB_PWRITE;
          s_req_wdata <= S_APB_PWDATA;
          s_req_wstrb <= S_APB_PWSTRB;
          s_req_prot  <= S_APB_PPROT;

          req_toggle  <= ~req_toggle;
          source_busy <= 1'b1;
        end
      end
      else if (S_APB_PREADY) begin
        source_busy <= 1'b0;
      end
      else if (resp_sync_2 == req_toggle) begin
        s_resp_data  <= m_resp_data;
        s_resp_error <= m_resp_error;
        S_APB_PREADY <= 1'b1;
      end
    end
  end

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_state       <= M_IDLE;
      M_APB_PSEL    <= 1'b0;
      M_APB_PENABLE <= 1'b0;
      req_seen      <= 1'b0;
      resp_toggle   <= 1'b0;

      m_req_addr  <= {C_APB_ADDR_WIDTH{1'b0}};
      m_req_write <= 1'b0;
      m_req_wdata <= {C_APB_DATA_WIDTH{1'b0}};
      m_req_wstrb <= {(C_APB_DATA_WIDTH/8){1'b0}};
      m_req_prot  <= 3'b000;

      m_resp_data  <= {C_APB_DATA_WIDTH{1'b0}};
      m_resp_error <= 1'b0;
    end
    else if (!M_PRESETn) begin
      m_state       <= M_IDLE;
      M_APB_PSEL    <= 1'b0;
      M_APB_PENABLE <= 1'b0;
      req_seen      <= 1'b0;
      resp_toggle   <= 1'b0;

      m_req_addr  <= {C_APB_ADDR_WIDTH{1'b0}};
      m_req_write <= 1'b0;
      m_req_wdata <= {C_APB_DATA_WIDTH{1'b0}};
      m_req_wstrb <= {(C_APB_DATA_WIDTH/8){1'b0}};
      m_req_prot  <= 3'b000;

      m_resp_data  <= {C_APB_DATA_WIDTH{1'b0}};
      m_resp_error <= 1'b0;
    end
    else begin
      case (m_state)
        M_IDLE: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;

          if (req_sync_2 != req_seen) begin
            req_seen <= req_sync_2;

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
            m_resp_data  <= M_APB_PRDATA;
            m_resp_error <= M_APB_PSLVERR;
            resp_toggle  <= req_seen;

            M_APB_PSEL    <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_state       <= M_IDLE;
          end
        end

        default: begin
          m_state       <= M_IDLE;
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;
        end
      endcase
    end
  end

endmodule
