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

  localparam integer C_APB_STRB_WIDTH = C_APB_DATA_WIDTH / 8;

  localparam [1:0] M_STATE_IDLE   = 2'd0;
  localparam [1:0] M_STATE_SETUP  = 2'd1;
  localparam [1:0] M_STATE_ACCESS = 2'd2;

  reg [1:0] m_reset_sync;

  reg req_toggle;
  reg req_busy;

  reg [C_APB_ADDR_WIDTH-1:0] req_addr_reg;
  reg                         req_write_reg;
  reg [C_APB_DATA_WIDTH-1:0] req_wdata_reg;
  reg [C_APB_STRB_WIDTH-1:0] req_wstrb_reg;
  reg [2:0]                  req_prot_reg;

  reg ack_sync_1;
  reg ack_sync_2;

  reg [C_APB_DATA_WIDTH-1:0] s_rsp_data_reg;
  reg                        s_rsp_error_reg;

  reg req_sync_1;
  reg req_sync_2;
  reg ack_toggle;

  reg [1:0] m_state;

  reg [C_APB_ADDR_WIDTH-1:0] m_addr_reg;
  reg                         m_write_reg;
  reg [C_APB_DATA_WIDTH-1:0] m_wdata_reg;
  reg [C_APB_STRB_WIDTH-1:0] m_wstrb_reg;
  reg [2:0]                  m_prot_reg;

  reg [C_APB_DATA_WIDTH-1:0] m_rsp_data_reg;
  reg                        m_rsp_error_reg;

  wire [C_APB_ADDR_WIDTH-1:0] req_addr_cross;
  wire                         req_write_cross;
  wire [C_APB_DATA_WIDTH-1:0] req_wdata_cross;
  wire [C_APB_STRB_WIDTH-1:0] req_wstrb_cross;
  wire [2:0]                  req_prot_cross;

  generate
    if (OPT_REGISTERED != 1'b0) begin : g_registered_crossing
      assign req_addr_cross  = req_addr_reg;
      assign req_write_cross = req_write_reg;
      assign req_wdata_cross = req_wdata_reg;
      assign req_wstrb_cross = req_wstrb_reg;
      assign req_prot_cross  = req_prot_reg;

      assign M_APB_PADDR  = m_addr_reg;
      assign M_APB_PWRITE = m_write_reg;
      assign M_APB_PWDATA = m_wdata_reg;
      assign M_APB_PWSTRB = m_wstrb_reg;
      assign M_APB_PPROT  = m_prot_reg;

      assign S_APB_PRDATA  = s_rsp_data_reg;
      assign S_APB_PSLVERR = s_rsp_error_reg;
    end else begin : g_unregistered_crossing
      assign req_addr_cross  = S_APB_PADDR;
      assign req_write_cross = S_APB_PWRITE;
      assign req_wdata_cross = S_APB_PWDATA;
      assign req_wstrb_cross = S_APB_PWSTRB;
      assign req_prot_cross  = S_APB_PPROT;

      assign M_APB_PADDR  = req_addr_cross;
      assign M_APB_PWRITE = req_write_cross;
      assign M_APB_PWDATA = req_wdata_cross;
      assign M_APB_PWSTRB = req_wstrb_cross;
      assign M_APB_PPROT  = req_prot_cross;

      assign S_APB_PRDATA  = m_rsp_data_reg;
      assign S_APB_PSLVERR = m_rsp_error_reg;
    end
  endgenerate

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_reset_sync <= 2'b00;
      M_PRESETn    <= 1'b0;
    end else begin
      m_reset_sync <= {m_reset_sync[0], 1'b1};
      M_PRESETn    <= m_reset_sync[1];
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      ack_sync_1 <= 1'b0;
      ack_sync_2 <= 1'b0;
    end else begin
      ack_sync_1 <= ack_toggle;
      ack_sync_2 <= ack_sync_1;
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      S_APB_PREADY   <= 1'b0;
      req_toggle     <= 1'b0;
      req_busy       <= 1'b0;
      req_addr_reg   <= {C_APB_ADDR_WIDTH{1'b0}};
      req_write_reg  <= 1'b0;
      req_wdata_reg  <= {C_APB_DATA_WIDTH{1'b0}};
      req_wstrb_reg  <= {C_APB_STRB_WIDTH{1'b0}};
      req_prot_reg   <= 3'b000;
      s_rsp_data_reg <= {C_APB_DATA_WIDTH{1'b0}};
      s_rsp_error_reg <= 1'b0;
    end else begin
      S_APB_PREADY <= 1'b0;

      if (!req_busy) begin
        if (S_APB_PSEL && !S_APB_PENABLE) begin
          req_addr_reg  <= S_APB_PADDR;
          req_write_reg <= S_APB_PWRITE;
          req_wdata_reg <= S_APB_PWDATA;
          req_wstrb_reg <= S_APB_PWSTRB;
          req_prot_reg  <= S_APB_PPROT;
          req_toggle    <= ~req_toggle;
          req_busy      <= 1'b1;
        end
      end else if (ack_sync_2 == req_toggle) begin
        s_rsp_data_reg  <= m_rsp_data_reg;
        s_rsp_error_reg <= m_rsp_error_reg;
        S_APB_PREADY    <= 1'b1;
        req_busy        <= 1'b0;
      end
    end
  end

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      req_sync_1 <= 1'b0;
      req_sync_2 <= 1'b0;
    end else if (!M_PRESETn) begin
      req_sync_1 <= 1'b0;
      req_sync_2 <= 1'b0;
    end else begin
      req_sync_1 <= req_toggle;
      req_sync_2 <= req_sync_1;
    end
  end

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      M_APB_PSEL      <= 1'b0;
      M_APB_PENABLE   <= 1'b0;
      ack_toggle      <= 1'b0;
      m_state         <= M_STATE_IDLE;
      m_addr_reg      <= {C_APB_ADDR_WIDTH{1'b0}};
      m_write_reg     <= 1'b0;
      m_wdata_reg     <= {C_APB_DATA_WIDTH{1'b0}};
      m_wstrb_reg     <= {C_APB_STRB_WIDTH{1'b0}};
      m_prot_reg      <= 3'b000;
      m_rsp_data_reg  <= {C_APB_DATA_WIDTH{1'b0}};
      m_rsp_error_reg <= 1'b0;
    end else if (!M_PRESETn) begin
      M_APB_PSEL      <= 1'b0;
      M_APB_PENABLE   <= 1'b0;
      ack_toggle      <= 1'b0;
      m_state         <= M_STATE_IDLE;
      m_addr_reg      <= {C_APB_ADDR_WIDTH{1'b0}};
      m_write_reg     <= 1'b0;
      m_wdata_reg     <= {C_APB_DATA_WIDTH{1'b0}};
      m_wstrb_reg     <= {C_APB_STRB_WIDTH{1'b0}};
      m_prot_reg      <= 3'b000;
      m_rsp_data_reg  <= {C_APB_DATA_WIDTH{1'b0}};
      m_rsp_error_reg <= 1'b0;
    end else begin
      case (m_state)
        M_STATE_IDLE: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;

          if (req_sync_2 != ack_toggle) begin
            m_addr_reg    <= req_addr_cross;
            m_write_reg   <= req_write_cross;
            m_wdata_reg   <= req_wdata_cross;
            m_wstrb_reg   <= req_wstrb_cross;
            m_prot_reg    <= req_prot_cross;
            M_APB_PSEL    <= 1'b1;
            M_APB_PENABLE <= 1'b0;
            m_state       <= M_STATE_SETUP;
          end
        end

        M_STATE_SETUP: begin
          M_APB_PSEL    <= 1'b1;
          M_APB_PENABLE <= 1'b1;
          m_state       <= M_STATE_ACCESS;
        end

        M_STATE_ACCESS: begin
          M_APB_PSEL    <= 1'b1;
          M_APB_PENABLE <= 1'b1;

          if (M_APB_PREADY) begin
            m_rsp_data_reg  <= M_APB_PRDATA;
            m_rsp_error_reg <= M_APB_PSLVERR;
            ack_toggle      <= req_sync_2;
            M_APB_PSEL      <= 1'b0;
            M_APB_PENABLE   <= 1'b0;
            m_state         <= M_STATE_IDLE;
          end
        end

        default: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;
          m_state       <= M_STATE_IDLE;
        end
      endcase
    end
  end

endmodule
