module axis_register #
(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter REG_TYPE = 2
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI Stream input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI Stream output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser
);

    // Internal signals
    wire s_axis_tvalid_int;
    wire s_axis_tready_int;
    wire m_axis_tvalid_int;
    wire m_axis_tready_int;

    // For REG_TYPE 0 (wire)
    wire wire_s_axis_tready;
    wire wire_m_axis_tvalid;
    wire [DATA_WIDTH-1:0] wire_m_axis_tdata;
    wire [KEEP_WIDTH-1:0] wire_m_axis_tkeep;
    wire wire_m_axis_tlast;
    wire [ID_WIDTH-1:0] wire_m_axis_tid;
    wire [DEST_WIDTH-1:0] wire_m_axis_tdest;
    wire [USER_WIDTH-1:0] wire_m_axis_tuser;

    // For REG_TYPE 1 (simple buffer)
    reg simple_buf_valid;
    reg [DATA_WIDTH-1:0] simple_buf_tdata;
    reg [KEEP_WIDTH-1:0] simple_buf_tkeep;
    reg simple_buf_tlast;
    reg [ID_WIDTH-1:0] simple_buf_tid;
    reg [DEST_WIDTH-1:0] simple_buf_tdest;
    reg [USER_WIDTH-1:0] simple_buf_tuser;

    wire simple_s_axis_tready;
    wire simple_m_axis_tvalid;
    wire [DATA_WIDTH-1:0] simple_m_axis_tdata;
    wire [KEEP_WIDTH-1:0] simple_m_axis_tkeep;
    wire simple_m_axis_tlast;
    wire [ID_WIDTH-1:0] simple_m_axis_tid;
    wire [DEST_WIDTH-1:0] simple_m_axis_tdest;
    wire [USER_WIDTH-1:0] simple_m_axis_tuser;

    // For REG_TYPE 2 (skid buffer)
    reg skid_buf_valid;
    reg [DATA_WIDTH-1:0] skid_buf_tdata;
    reg [KEEP_WIDTH-1:0] skid_buf_tkeep;
    reg skid_buf_tlast;
    reg [ID_WIDTH-1:0] skid_buf_tid;
    reg [DEST_WIDTH-1:0] skid_buf_tdest;
    reg [USER_WIDTH-1:0] skid_buf_tuser;

    reg skid_skid_valid;
    reg [DATA_WIDTH-1:0] skid_skid_tdata;
    reg [KEEP_WIDTH-1:0] skid_skid_tkeep;
    reg skid_skid_tlast;
    reg [ID_WIDTH-1:0] skid_skid_tid;
    reg [DEST_WIDTH-1:0] skid_skid_tdest;
    reg [USER_WIDTH-1:0] skid_skid_tuser;

    wire skid_s_axis_tready;
    wire skid_m_axis_tvalid;
    wire [DATA_WIDTH-1:0] skid_m_axis_tdata;
    wire [KEEP_WIDTH-1:0] skid_m_axis_tkeep;
    wire skid_m_axis_tlast;
    wire [ID_WIDTH-1:0] skid_m_axis_tid;
    wire [DEST_WIDTH-1:0] skid_m_axis_tdest;
    wire [USER_WIDTH-1:0] skid_m_axis_tuser;

    // Wire implementation (REG_TYPE 0)
    assign wire_s_axis_tready = m_axis_tready;
    assign wire_m_axis_tvalid = s_axis_tvalid;
    assign wire_m_axis_tdata = s_axis_tdata;
    assign wire_m_axis_tkeep = s_axis_tkeep;
    assign wire_m_axis_tlast = s_axis_tlast;
    assign wire_m_axis_tid = s_axis_tid;
    assign wire_m_axis_tdest = s_axis_tdest;
    assign wire_m_axis_tuser = s_axis_tuser;

    // Simple buffer implementation (REG_TYPE 1)
    assign simple_s_axis_tready = !simple_buf_valid;
    assign simple_m_axis_tvalid = simple_buf_valid;
    assign simple_m_axis_tdata = simple_buf_tdata;
    assign simple_m_axis_tkeep = simple_buf_tkeep;
    assign simple_m_axis_tlast = simple_buf_tlast;
    assign simple_m_axis_tid = simple_buf_tid;
    assign simple_m_axis_tdest = simple_buf_tdest;
    assign simple_m_axis_tuser = simple_buf_tuser;

    wire simple_buf_write = s_axis_tvalid && simple_s_axis_tready;
    wire simple_buf_read = simple_m_axis_tvalid && m_axis_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            simple_buf_valid <= 1'b0;
            simple_buf_tdata <= {DATA_WIDTH{1'b0}};
            simple_buf_tkeep <= {KEEP_WIDTH{1'b0}};
            simple_buf_tlast <= 1'b0;
            simple_buf_tid <= {ID_WIDTH{1'b0}};
            simple_buf_tdest <= {DEST_WIDTH{1'b0}};
            simple_buf_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            if (simple_buf_write) begin
                simple_buf_valid <= 1'b1;
                simple_buf_tdata <= s_axis_tdata;
                simple_buf_tkeep <= s_axis_tkeep;
                simple_buf_tlast <= s_axis_tlast;
                simple_buf_tid <= s_axis_tid;
                simple_buf_tdest <= s_axis_tdest;
                simple_buf_tuser <= s_axis_tuser;
            end
            if (simple_buf_read) begin
                simple_buf_valid <= 1'b0;
            end
            if (simple_buf_write && simple_buf_read) begin
                simple_buf_valid <= 1'b1;
                simple_buf_tdata <= s_axis_tdata;
                simple_buf_tkeep <= s_axis_tkeep;
                simple_buf_tlast <= s_axis_tlast;
                simple_buf_tid <= s_axis_tid;
                simple_buf_tdest <= s_axis_tdest;
                simple_buf_tuser <= s_axis_tuser;
            end
        end
    end

    // Skid buffer implementation (REG_TYPE 2)
    // The main buffer holds the current beat, the skid buffer holds the next beat
    assign skid_s_axis_tready = !skid_buf_valid || (skid_m_axis_tvalid && m_axis_tready);
    assign skid_m_axis_tvalid = skid_buf_valid;
    assign skid_m_axis_tdata = skid_buf_tdata;
    assign skid_m_axis_tkeep = skid_buf_tkeep;
    assign skid_m_axis_tlast = skid_buf_tlast;
    assign skid_m_axis_tid = skid_buf_tid;
    assign skid_m_axis_tdest = skid_buf_tdest;
    assign skid_m_axis_tuser = skid_buf_tuser;

    wire skid_buf_write = s_axis_tvalid && skid_s_axis_tready;
    wire skid_buf_read = skid_m_axis_tvalid && m_axis_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            skid_buf_valid <= 1'b0;
            skid_buf_tdata <= {DATA_WIDTH{1'b0}};
            skid_buf_tkeep <= {KEEP_WIDTH{1'b0}};
            skid_buf_tlast <= 1'b0;
            skid_buf_tid <= {ID_WIDTH{1'b0}};
            skid_buf_tdest <= {DEST_WIDTH{1'b0}};
            skid_buf_tuser <= {USER_WIDTH{1'b0}};
            skid_skid_valid <= 1'b0;
            skid_skid_tdata <= {DATA_WIDTH{1'b0}};
            skid_skid_tkeep <= {KEEP_WIDTH{1'b0}};
            skid_skid_tlast <= 1'b0;
            skid_skid_tid <= {ID_WIDTH{1'b0}};
            skid_skid_tdest <= {DEST_WIDTH{1'b0}};
            skid_skid_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            // If main buffer is empty, write to main buffer
            if (!skid_buf_valid) begin
                if (skid_buf_write) begin
                    skid_buf_valid <= 1'b1;
                    skid_buf_tdata <= s_axis_tdata;
                    skid_buf_tkeep <= s_axis_tkeep;
                    skid_buf_tlast <= s_axis_tlast;
                    skid_buf_tid <= s_axis_tid;
                    skid_buf_tdest <= s_axis_tdest;
                    skid_buf_tuser <= s_axis_tuser;
                end
            end else begin
                // Main buffer is full
                if (skid_buf_read) begin
                    // Main buffer is being read out
                    if (skid_buf_write) begin
                        // New data coming in, move skid to main, new data to skid
                        skid_buf_tdata <= skid_skid_tdata;
                        skid_buf_tkeep <= skid_skid_tkeep;
                        skid_buf_tlast <= skid_skid_tlast;
                        skid_buf_tid <= skid_skid_tid;
                        skid_buf_tdest <= skid_skid_tdest;
                        skid_buf_tuser <= skid_skid_tuser;
                        skid_skid_tdata <= s_axis_tdata;
                        skid_skid_tkeep <= s_axis_tkeep;
                        skid_skid_tlast <= s_axis_tlast;
                        skid_skid_tid <= s_axis_tid;
                        skid_skid_tdest <= s_axis_tdest;
                        skid_skid_tuser <= s_axis_tuser;
                        skid_skid_valid <= 1'b1;
                    end else begin
                        // No new data, move skid to main
                        skid_buf_tdata <= skid_skid_tdata;
                        skid_buf_tkeep <= skid_skid_tkeep;
                        skid_buf_tlast <= skid_skid_tlast;
                        skid_buf_tid <= skid_skid_tid;
                        skid_buf_tdest <= skid_skid_tdest;
                        skid_buf_tuser <= skid_skid_tuser;
                        skid_skid_valid <= 1'b0;
                    end
                end else begin
                    // Main buffer is not being read out
                    if (skid_buf_write) begin
                        // New data coming in, store in skid buffer
                        skid_skid_tdata <= s_axis_tdata;
                        skid_skid_tkeep <= s_axis_tkeep;
                        skid_skid_tlast <= s_axis_tlast;
                        skid_skid_tid <= s_axis_tid;
                        skid_skid_tdest <= s_axis_tdest;
                        skid_skid_tuser <= s_axis_tuser;
                        skid_skid_valid <= 1'b1;
                    end
                end
            end
        end
    end

    // Mux based on REG_TYPE
    generate
        if (REG_TYPE == 0) begin : gen_wire
            assign s_axis_tready = wire_s_axis_tready;
            assign m_axis_tvalid = wire_m_axis_tvalid;
            assign m_axis_tdata = wire_m_axis_tdata;
            assign m_axis_tkeep = wire_m_axis_tkeep;
            assign m_axis_tlast = wire_m_axis_tlast;
            assign m_axis_tid = wire_m_axis_tid;
            assign m_axis_tdest = wire_m_axis_tdest;
            assign m_axis_tuser = wire_m_axis_tuser;
        end
        else if (REG_TYPE == 1) begin : gen_simple
            assign s_axis_tready = simple_s_axis_tready;
            assign m_axis_tvalid = simple_m_axis_tvalid;
            assign m_axis_tdata = simple_m_axis_tdata;
            assign m_axis_tkeep = simple_m_axis_tkeep;
            assign m_axis_tlast = simple_m_axis_tlast;
            assign m_axis_tid = simple_m_axis_tid;
            assign m_axis_tdest = simple_m_axis_tdest;
            assign m_axis_tuser = simple_m_axis_tuser;
        end
        else begin : gen_skid
            assign s_axis_tready = skid_s_axis_tready;
            assign m_axis_tvalid = skid_m_axis_tvalid;
            assign m_axis_tdata = skid_m_axis_tdata;
            assign m_axis_tkeep = skid_m_axis_tkeep;
            assign m_axis_tlast = skid_m_axis_tlast;
            assign m_axis_tid = skid_m_axis_tid;
            assign m_axis_tdest = skid_m_axis_tdest;
            assign m_axis_tuser = skid_m_axis_tuser;
        end
    endgenerate

endmodule
