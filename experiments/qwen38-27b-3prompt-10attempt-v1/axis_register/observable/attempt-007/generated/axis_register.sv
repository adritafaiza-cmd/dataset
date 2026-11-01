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
    wire [DATA_WIDTH-1:0]  reg_tdata;
    wire [KEEP_WIDTH-1:0]  reg_tkeep;
    wire                   reg_tvalid;
    wire                   reg_tlast;
    wire [ID_WIDTH-1:0]    reg_tid;
    wire [DEST_WIDTH-1:0]  reg_tdest;
    wire [USER_WIDTH-1:0]  reg_tuser;

    // Skid buffer registers
    reg  [DATA_WIDTH-1:0]  skid_tdata;
    reg  [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                    skid_tvalid;
    reg                    skid_tlast;
    reg  [ID_WIDTH-1:0]    skid_tid;
    reg  [DEST_WIDTH-1:0]  skid_tdest;
    reg  [USER_WIDTH-1:0]  skid_tuser;

    // Main register
    reg  [DATA_WIDTH-1:0]  main_tdata;
    reg  [KEEP_WIDTH-1:0]  main_tkeep;
    reg                    main_tvalid;
    reg                    main_tlast;
    reg  [ID_WIDTH-1:0]    main_tid;
    reg  [DEST_WIDTH-1:0]  main_tdest;
    reg  [USER_WIDTH-1:0]  main_tuser;

    // Control signals
    wire                   s_axis_tready_internal;
    wire                   m_axis_tvalid_internal;

    // Determine if we can accept new data
    wire                   can_accept;
    wire                   can_forward;

    // For REG_TYPE = 0: wire (no register)
    // For REG_TYPE = 1: buffer (single register)
    // For REG_TYPE = 2: skid buffer (two registers)

    // Wire mode: direct passthrough
    assign m_axis_tdata  = (REG_TYPE == 0) ? s_axis_tdata  : (skid_tvalid ? skid_tdata  : main_tdata);
    assign m_axis_tkeep  = (REG_TYPE == 0) ? s_axis_tkeep  : (skid_tvalid ? skid_tkeep  : main_tkeep);
    assign m_axis_tvalid = (REG_TYPE == 0) ? s_axis_tvalid : (skid_tvalid ? skid_tvalid : main_tvalid);
    assign m_axis_tlast  = (REG_TYPE == 0) ? s_axis_tlast  : (skid_tvalid ? skid_tlast  : main_tlast);
    assign m_axis_tid    = (REG_TYPE == 0) ? s_axis_tid    : (skid_tvalid ? skid_tid    : main_tid);
    assign m_axis_tdest  = (REG_TYPE == 0) ? s_axis_tdest  : (skid_tvalid ? skid_tdest  : main_tdest);
    assign m_axis_tuser  = (REG_TYPE == 0) ? s_axis_tuser  : (skid_tvalid ? skid_tuser  : main_tuser);

    // Ready signal
    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready : 
                           (REG_TYPE == 1) ? (main_tvalid ? m_axis_tready : 1'b1) :
                           (skid_tvalid ? m_axis_tready : (main_tvalid ? m_axis_tready : 1'b1));

    // For REG_TYPE = 0: wire
    // For REG_TYPE = 1: simple buffer
    // For REG_TYPE = 2: skid buffer

    // Simple buffer logic (REG_TYPE = 1)
    // Main register holds data, forwards when m_axis_tready
    // Accepts new data when main is empty or forwarding

    // Skid buffer logic (REG_TYPE = 2)
    // Two registers: main and skid
    // Data flows: s_axis -> main -> skid -> m_axis
    // Or: s_axis -> main -> m_axis (if skid empty)

    // Let's implement using a state machine approach for clarity

    // For REG_TYPE = 1 (buffer):
    // - main_tvalid indicates if main register has data
    // - s_axis_tready = !main_tvalid || m_axis_tready
    // - When s_axis_tvalid && s_axis_tready: load main
    // - When main_tvalid && m_axis_tready: forward main to m_axis, clear main

    // For REG_TYPE = 2 (skid buffer):
    // - Two stages: main and skid
    // - s_axis_tready = !main_tvalid || (main_tvalid && !skid_tvalid && m_axis_tready) || (main_tvalid && skid_tvalid && m_axis_tready)
    // Actually, let's think more carefully.

    // Skid buffer:
    // State: main has data? skid has data?
    // If main empty: accept from s_axis, load main
    // If main full, skid empty: 
    //   - If m_axis_tready: forward main to m_axis, accept from s_axis to main
    //   - Else: s_axis_tready = 0
    // If main full, skid full:
    //   - If m_axis_tready: forward main to skid, forward skid to m_axis, accept from s_axis to main
    //   - Else: s_axis_tready = 0

    // Let's implement this properly

    // For REG_TYPE = 1:
    wire buf_s_axis_tready;
    wire buf_m_axis_tvalid;
    wire [DATA_WIDTH-1:0] buf_m_axis_tdata;
    wire [KEEP_WIDTH-1:0] buf_m_axis_tkeep;
    wire buf_m_axis_tlast;
    wire [ID_WIDTH-1:0] buf_m_axis_tid;
    wire [DEST_WIDTH-1:0] buf_m_axis_tdest;
    wire [USER_WIDTH-1:0] buf_m_axis_tuser;

    assign buf_s_axis_tready = !main_tvalid || m_axis_tready;
    assign buf_m_axis_tvalid = main_tvalid;
    assign buf_m_axis_tdata  = main_tdata;
    assign buf_m_axis_tkeep  = main_tkeep;
    assign buf_m_axis_tlast  = main_tlast;
    assign buf_m_axis_tid    = main_tid;
    assign buf_m_axis_tdest  = main_tdest;
    assign buf_m_axis_tuser  = main_tuser;

    // For REG_TYPE = 2:
    wire skid_s_axis_tready;
    wire skid_m_axis_tvalid;
    wire [DATA_WIDTH-1:0] skid_m_axis_tdata;
    wire [KEEP_WIDTH-1:0] skid_m_axis_tkeep;
    wire skid_m_axis_tlast;
    wire [ID_WIDTH-1:0] skid_m_axis_tid;
    wire [DEST_WIDTH-1:0] skid_m_axis_tdest;
    wire [USER_WIDTH-1:0] skid_m_axis_tuser;

    // Skid buffer logic
    // main_tvalid, skid_tvalid are the states
    // s_axis_tready:
    //   - If !main_tvalid: 1
    //   - If main_tvalid && !skid_tvalid: m_axis_tready
    //   - If main_tvalid && skid_tvalid: m_axis_tready
    assign skid_s_axis_tready = !main_tvalid || m_axis_tready;

    // m_axis_tvalid:
    //   - If main_tvalid: 1
    //   - If !main_tvalid && skid_tvalid: 1
    assign skid_m_axis_tvalid = main_tvalid || skid_tvalid;

    // m_axis_tdata:
    //   - If main_tvalid: main_tdata
    //   - If !main_tvalid && skid_tvalid: skid_tdata
    assign skid_m_axis_tdata  = main_tvalid ? main_tdata : skid_tdata;
    assign skid_m_axis_tkeep  = main_tvalid ? main_tkeep : skid_tkeep;
    assign skid_m_axis_tlast  = main_tvalid ? main_tlast : skid_tlast;
    assign skid_m_axis_tid    = main_tvalid ? main_tid   : skid_tid;
    assign skid_m_axis_tdest  = main_tvalid ? main_tdest : skid_tdest;
    assign skid_m_axis_tuser  = main_tvalid ? main_tuser : skid_tuser;

    // Now select based on REG_TYPE
    assign m_axis_tdata  = (REG_TYPE == 0) ? s_axis_tdata  : (REG_TYPE == 1) ? buf_m_axis_tdata  : skid_m_axis_tdata;
    assign m_axis_tkeep  = (REG_TYPE == 0) ? s_axis_tkeep  : (REG_TYPE == 1) ? buf_m_axis_tkeep  : skid_m_axis_tkeep;
    assign m_axis_tvalid = (REG_TYPE == 0) ? s_axis_tvalid : (REG_TYPE == 1) ? buf_m_axis_tvalid : skid_m_axis_tvalid;
    assign m_axis_tlast  = (REG_TYPE == 0) ? s_axis_tlast  : (REG_TYPE == 1) ? buf_m_axis_tlast  : skid_m_axis_tlast;
    assign m_axis_tid    = (REG_TYPE == 0) ? s_axis_tid    : (REG_TYPE == 1) ? buf_m_axis_tid    : skid_m_axis_tid;
    assign m_axis_tdest  = (REG_TYPE == 0) ? s_axis_tdest  : (REG_TYPE == 1) ? buf_m_axis_tdest  : skid_m_axis_tdest;
    assign m_axis_tuser  = (REG_TYPE == 0) ? s_axis_tuser  : (REG_TYPE == 1) ? buf_m_axis_tuser  : skid_m_axis_tuser;

    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready : (REG_TYPE == 1) ? buf_s_axis_tready : skid_s_axis_tready;

    // Register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            main_tvalid <= 1'b0;
            skid_tvalid <= 1'b0;
            main_tdata  <= {DATA_WIDTH{1'b0}};
            main_tkeep  <= {KEEP_WIDTH{1'b0}};
            main_tlast  <= 1'b0;
            main_tid    <= {ID_WIDTH{1'b0}};
            main_tdest  <= {DEST_WIDTH{1'b0}};
            main_tuser  <= {USER_WIDTH{1'b0}};
            skid_tdata  <= {DATA_WIDTH{1'b0}};
            skid_tkeep  <= {KEEP_WIDTH{1'b0}};
            skid_tlast  <= 1'b0;
            skid_tid    <= {ID_WIDTH{1'b0}};
            skid_tdest  <= {DEST_WIDTH{1'b0}};
            skid_tuser  <= {USER_WIDTH{1'b0}};
        end else begin
            if (REG_TYPE == 1) begin
                // Buffer mode
                if (main_tvalid && m_axis_tready) begin
                    // Forward main to m_axis
                    if (s_axis_tvalid && buf_s_axis_tready) begin
                        // Load new data into main
                        main_tdata  <= s_axis_tdata;
                        main_tkeep  <= s_axis_tkeep;
                        main_tlast  <= s_axis_tlast;
                        main_tid    <= s_axis_tid;
                        main_tdest  <= s_axis_tdest;
                        main_tuser  <= s_axis_tuser;
                        main_tvalid <= 1'b1;
                    end else begin
                        main_tvalid <= 1'b0;
                    end
                end else if (s_axis_tvalid && buf_s_axis_tready) begin
                    // Load new data into main
                    main_tdata  <= s_axis_tdata;
                    main_tkeep  <= s_axis_tkeep;
                    main_tlast  <= s_axis_tlast;
                    main_tid    <= s_axis_tid;
                    main_tdest  <= s_axis_tdest;
                    main_tuser  <= s_axis_tuser;
                    main_tvalid <= 1'b1;
                end
            end else if (REG_TYPE == 2) begin
                // Skid buffer mode
                // Determine what happens this cycle
                // Cases:
                // 1. main empty: accept from s_axis to main
                // 2. main full, skid empty:
                //    a. m_axis_tready: forward main to m_axis, accept s_axis to main
                //    b. !m_axis_tready: do nothing
                // 3. main full, skid full:
                //    a. m_axis_tready: forward main to skid, forward skid to m_axis, accept s_axis to main
                //    b. !m_axis_tready: do nothing

                if (!main_tvalid) begin
                    // Main is empty
                    if (s_axis_tvalid && skid_s_axis_tready) begin
                        main_tdata  <= s_axis_tdata;
                        main_tkeep  <= s_axis_tkeep;
                        main_tlast  <= s_axis_tlast;
                        main_tid    <= s_axis_tid;
                        main_tdest  <= s_axis_tdest;
                        main_tuser  <= s_axis_tuser;
                        main_tvalid <= 1'b1;
                    end
                end else if (!skid_tvalid) begin
                    // Main full, skid empty
                    if (m_axis_tready) begin
                        // Forward main to m_axis
                        if (s_axis_tvalid && skid_s_axis_tready) begin
                            // Load new data into main
                            main_tdata  <= s_axis_tdata;
                            main_tkeep  <= s_axis_tkeep;
                            main_tlast  <= s_axis_tlast;
                            main_tid    <= s_axis_tid;
                            main_tdest  <= s_axis_tdest;
                            main_tuser  <= s_axis_tuser;
                            main_tvalid <= 1'b1;
                        end else begin
                            main_tvalid <= 1'b0;
                        end
                    end
                end else begin
                    // Main full, skid full
                    if (m_axis_tready) begin
                        // Forward main to skid, forward skid to m_axis
                        skid_tdata  <= main_tdata;
                        skid_tkeep  <= main_tkeep;
                        skid_tlast  <= main_tlast;
                        skid_tid    <= main_tid;
                        skid_tdest  <= main_tdest;
                        skid_tuser  <= main_tuser;
                        skid_tvalid <= 1'b1;

                        if (s_axis_tvalid && skid_s_axis_tready) begin
                            // Load new data into main
                            main_tdata  <= s_axis_tdata;
                            main_tkeep  <= s_axis_tkeep;
                            main_tlast  <= s_axis_tlast;
                            main_tid    <= s_axis_tid;
                            main_tdest  <= s_axis_tdest;
                            main_tuser  <= s_axis_tuser;
                            main_tvalid <= 1'b1;
                        end else begin
                            main_tvalid <= 1'b0;
                        end
                    end
                end
            end
        end
    end

endmodule
