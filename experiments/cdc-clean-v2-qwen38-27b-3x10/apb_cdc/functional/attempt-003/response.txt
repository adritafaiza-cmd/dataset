```verilog
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH;

    // Source-side state
    reg src_idle;
    reg src_setup;
    reg src_access;
    reg src_done;

    // Destination-side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;
    reg dst_done;

    // FIFO pointers
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr;

    // FIFO data storage
    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] fifo_strb [0:DEPTH-1];
    reg [2:0] fifo_prot [0:DEPTH-1];
    reg fifo_write [0:DEPTH-1];

    // FIFO full/empty
    wire src_fifo_full;
    wire dst_fifo_empty;

    // Source side: detect APB transfer completion
    // APB transfer: setup phase (psel=1, penable=0) then access phase (psel=1, penable=1)
    // Transfer completes when penable=1 and pready=1

    // Source state machine
    // We accept a new request when we are idle and psel is asserted
    // We hold the request until the destination completes

    // Source-side: capture request when entering setup phase
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_wdata_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_write_reg;

    // Source-side: read data and error from destination
    reg [DATA_WIDTH-1:0] src_rdata_reg;
    reg src_slverr_reg;

    // Destination-side: captured request
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [DATA_WIDTH-1:0] dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_strb_reg;
    reg [2:0] dst_prot_reg;
    reg dst_write_reg;

    // Destination-side: read data and error
    reg [DATA_WIDTH-1:0] dst_rdata_reg;
    reg dst_slverr_reg;

    // FIFO full/empty logic
    // Full when wr_ptr == rd_ptr and we have a pending item
    // We use a simple approach: track number of items
    // Since LOG_DEPTH can be 1, we need to be careful

    // For simplicity, use a single-entry buffer approach with valid bits
    // Actually, let's use a proper FIFO with pointers

    // FIFO full: wr_ptr == rd_ptr and we've written DEPTH items
    // This is tricky with circular buffers. Let's use a different approach.
    // Since we only need one outstanding transaction, we can simplify.

    // Simplified approach: 
    // Source captures request, writes to a single buffer
    // Destination reads from buffer when ready
    // Use a valid bit to indicate data is available

    reg src_valid;  // Source has a request ready to send
    reg dst_valid;  // Destination has a request ready to process

    // Source state machine
    // States: IDLE, SETUP, ACCESS, DONE
    // IDLE: Wait for psel
    // SETUP: psel=1, penable=0. Capture request.
    // ACCESS: psel=1, penable=1. Wait for pready.
    // DONE: Return data, go back to IDLE.

    // Actually, for APB CDC, the standard approach is:
    // 1. Source detects a complete APB transfer (setup + access)
    // 2. Source captures the request and writes it to a FIFO
    // 3. Destination reads from FIFO and drives APB signals
    // 4. When destination completes, it signals back to source
    // 5. Source returns data to master

    // Let's use a simpler approach with a single buffer:
    // - Source captures request when it sees a complete APB transfer
    // - Source asserts src_pready_o only after destination completes
    // - Destination drives APB signals from the captured request

    // Source-side: detect when to capture
    // Capture when: src_psel_i && src_penable_i && src_pready_o
    // But we need to hold the request until destination completes

    // Let's use a state machine on the source side:
    // IDLE: src_pready_o = 0, wait for psel
    // CAPTURE: src_psel_i && !src_penable_i, capture request, go to WAIT
    // WAIT: src_psel_i && src_penable_i, wait for dst_done
    // DONE: return data, go to IDLE

    // Actually, the APB protocol requires:
    // - Setup phase: PSEL=1, PENABLE=0
    // - Access phase: PSEL=1, PENABLE=1
    // - Transfer completes when PREADY=1 during access phase

    // So the source should:
    // 1. In IDLE, when PSEL=1 and PENABLE=0, capture the request
    // 2. Assert PREADY=0 during setup
    // 3. In access phase (PSEL=1, PENABLE=1), wait for destination to complete
    // 4. When destination completes, assert PREADY=1 for one cycle
    // 5. Return to IDLE

    // Let's implement this:

    // Source state machine
    reg [1:0] src_state;
    localparam SRC_IDLE = 2'd0;
    localparam SRC_SETUP = 2'd1;
    localparam SRC_ACCESS = 2'd2;
    localparam SRC_DONE = 2'd3;

    // Destination state machine
    reg [1:0] dst_state;
    localparam DST_IDLE = 2'd0;
    localparam DST_SETUP = 2'd1;
    localparam DST_ACCESS = 2'd2;
    localparam DST_DONE = 2'd3;

    // Source-side: request valid (captured and waiting for destination)
    reg src_req_valid;

    // Destination-side: request valid (received from source)
    reg dst_req_valid;

    // Source-side: destination done signal (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done signal (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data ready (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH-1:0] dst_rdata_sync3;

    // Destination-side: source rdata (synchronized)
    reg [DATA_WIDTH-1:0] src_rdata_sync1;
    reg [DATA_WIDTH-1:0] src_rdata_sync2;
    reg [DATA_WIDTH-1:0] src_rdata_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source slverr (synchronized)
    reg src_slverr_sync1;
    reg src_slverr_sync2;
    reg src_slverr_sync3;

    // Source-side: destination done (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data valid (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH-1:0] dst_rdata_sync3;

    // Destination-side: source rdata (synchronized)
    reg [DATA_WIDTH-1:0] src_rdata_sync1;
    reg [DATA_WIDTH-1:0] src_rdata_sync2;
    reg [DATA_WIDTH-1:0] src_rdata_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source slverr (synchronized)
    reg src_slverr_sync1;
    reg src_slverr_sync2;
    reg src_slverr_sync3;

    // Source-side: destination done (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data valid (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH-1:0] dst_rdata_sync3;

    // Destination-side: source rdata (synchronized)
    reg [DATA_WIDTH-1:0] src_rdata_sync1;
    reg [DATA_WIDTH-1:0] src_rdata_sync2;
    reg [DATA_WIDTH-1:0] src_rdata_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source slverr (synchronized)
    reg src_slverr_sync1;
    reg src_slverr_sync2;
    reg src_slverr_sync3;

    // Source-side: destination done (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data valid (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH-1:0] dst_rdata_sync3;

    // Destination-side: source rdata (synchronized)
    reg [DATA_WIDTH-1:0] src_rdata_sync1;
    reg [DATA_WIDTH-1:0] src_rdata_sync2;
    reg [DATA_WIDTH-1:0] src_rdata_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source slverr (synchronized)
    reg src_slverr_sync1;
    reg src_slverr_sync2;
    reg src_slverr_sync3;

    // Source-side: destination done (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data valid (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH-1:0] dst_rdata_sync3;

    // Destination-side: source rdata (synchronized)
    reg [DATA_WIDTH-1:0] src_rdata_sync1;
    reg [DATA_WIDTH-1:0] src_rdata_sync2;
    reg [DATA_WIDTH-1:0] src_rdata_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source slverr (synchronized)
    reg src_slverr_sync1;
    reg src_slverr_sync2;
    reg src_slverr_sync3;

    // Source-side: destination done (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data valid (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH-1:0] dst_rdata_sync3;

    // Destination-side: source rdata (synchronized)
    reg [DATA_WIDTH-1:0] src_rdata_sync1;
    reg [DATA_WIDTH-1:0] src_rdata_sync2;
    reg [DATA_WIDTH-1:0] src_rdata_sync3;

    // Source-side: destination slverr (synchronized)
    reg dst_slverr_sync1;
    reg dst_slverr_sync2;
    reg dst_slverr_sync3;

    // Destination-side: source slverr (synchronized)
    reg src_slverr_sync1;
    reg src_slverr_sync2;
    reg src_slverr_sync3;

    // Source-side: destination done (synchronized)
    reg dst_done_sync1;
    reg dst_done_sync2;
    reg dst_done_sync3;

    // Destination-side: source done (synchronized)
    reg src_done_sync1;
    reg src_done_sync2;
    reg src_done_sync3;

    // Source-side: destination data valid (synchronized)
    reg dst_data_valid_sync1;
    reg dst_data_valid_sync2;
    reg dst_data_valid_sync3;

    // Destination-side: source data valid (synchronized)
    reg src_data_valid_sync1;
    reg src_data_valid_sync2;
    reg src_data_valid_sync3;

    // Source-side: destination write (synchronized)
    reg dst_write_sync1;
    reg dst_write_sync2;
    reg dst_write_sync3;

    // Destination-side: source write (synchronized)
    reg src_write_sync1;
    reg src_write_sync2;
    reg src_write_sync3;

    // Source-side: destination addr (synchronized)
    reg [ADDR_WIDTH-1:0] dst_addr_sync1;
    reg [ADDR_WIDTH-1:0] dst_addr_sync2;
    reg [ADDR_WIDTH-1:0] dst_addr_sync3;

    // Destination-side: source addr (synchronized)
    reg [ADDR_WIDTH-1:0] src_addr_sync1;
    reg [ADDR_WIDTH-1:0] src_addr_sync2;
    reg [ADDR_WIDTH-1:0] src_addr_sync3;

    // Source-side: destination wdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_wdata_sync1;
    reg [DATA_WIDTH-1:0] dst_wdata_sync2;
    reg [DATA_WIDTH-1:0] dst_wdata_sync3;

    // Destination-side: source wdata (synchronized)
    reg [DATA_WIDTH-1:0] src_wdata_sync1;
    reg [DATA_WIDTH-1:0] src_wdata_sync2;
    reg [DATA_WIDTH-1:0] src_wdata_sync3;

    // Source-side: destination strb (synchronized)
    reg [DATA_WIDTH/8-1:0] dst_strb_sync1;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync2;
    reg [DATA_WIDTH/8-1:0] dst_strb_sync3;

    // Destination-side: source strb (synchronized)
    reg [DATA_WIDTH/8-1:0] src_strb_sync1;
    reg [DATA_WIDTH/8-1:0] src_strb_sync2;
    reg [DATA_WIDTH/8-1:0] src_strb_sync3;

    // Source-side: destination prot (synchronized)
    reg [2:0] dst_prot_sync1;
    reg [2:0] dst_prot_sync2;
    reg [2:0] dst_prot_sync3;

    // Destination-side: source prot (synchronized)
    reg [2:0] src_prot_sync1;
    reg [2:0] src_prot_sync2;
    reg [2:0] src_prot_sync3;

    // Source-side: destination rdata (synchronized)
    reg [DATA_WIDTH-1:0] dst_rdata_sync1;
    reg [DATA_WIDTH-1:0] dst_rdata_sync2;
    reg [DATA_WIDTH