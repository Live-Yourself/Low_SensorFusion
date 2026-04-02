module ahb2apb_bridge (
  input  logic        hclk,
  input  logic        hresetn,
  input  logic        hsel,
  input  logic [31:0] haddr,
  input  logic [1:0]  htrans,
  input  logic        hwrite,
  input  logic [31:0] hwdata,
  output logic [31:0] hrdata,
  output logic        hreadyout,
  output logic        hresp,
  output logic        psel,
  output logic        penable,
  output logic        pwrite,
  output logic [31:0] paddr,
  output logic [31:0] pwdata,
  input  logic [31:0] prdata,
  input  logic        pready,
  input  logic        pslverr
);
  always_comb begin
    psel     = hsel & htrans[1];
    penable  = psel;
    pwrite   = hwrite;
    paddr    = haddr;
    pwdata   = hwdata;
    hrdata   = prdata;
    hreadyout= pready;
    hresp    = pslverr;
  end
endmodule
