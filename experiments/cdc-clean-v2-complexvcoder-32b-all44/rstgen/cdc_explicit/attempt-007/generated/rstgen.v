module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic sync_rst_o;

    // Instantiate the sync_reset module
    sync_reset sync_reset_inst (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sync_rst_o (sync_rst_o)
    );

    // Assign rst_no based on test_mode_i and sync_rst_o
    assign rst_no = test_mode_i ? rst_ni : sync_rst_o;

    // Assign init_no to be active only when sync_rst_o is deasserted (reset is released)
    assign init_no = ~sync_rst_o & sync_rst_o;

endmodule

module sync_reset (
    input  logic clk_i,
    input  logic rst_ni,
    output logic sync_rst_o
);

    logic rst_sync_reg1;
    logic rst_sync_reg2;

    // Two-stage synchronizer for the reset signal
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_reg1 <= 1'b1;
            rst_sync_reg2 <= 1'b1;
        end else begin
            rst_sync_reg1 <= 1'b0;
            rst_sync_reg2 <= rst_sync_reg1;
        end
    end

    // Synchronized reset output
    assign sync_rst_o = rst_sync_reg2;

endmodule
