class soc_env extends uvm_env;
  `uvm_component_utils(soc_env)

  virtual apb_if apb_vif;
  apb_agent      m_apb_agent;
  soc_scoreboard m_scb;
  soc_cov        m_cov;

  function new(string name = "soc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
      `uvm_fatal("NOVIF", "apb_vif not found from config_db")
    end

    uvm_config_db#(virtual apb_if)::set(this, "m_apb_agent", "apb_vif", apb_vif);
    m_apb_agent = apb_agent::type_id::create("m_apb_agent", this);
    m_scb       = soc_scoreboard::type_id::create("m_scb", this);
    m_cov       = soc_cov::type_id::create("m_cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_apb_agent.mon.ap.connect(m_scb.apb_imp);
    m_apb_agent.mon.ap.connect(m_cov.apb_imp);
  endfunction
endclass
