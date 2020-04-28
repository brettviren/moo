// 100% generated, do not edit.



// Data interface implementation for Frame 
class WireCell::PB::Frame : public WireCell::IFrame {
  public:
    Frame(const wct::pb::Frame& o) {
        m_ident = o.ident();
        
        m_time = o.time();
        
        m_tick = o.tick();
        pbiface_set(m_, o);
        {
            size_t siz = o.frame_tags_size();
            m_frame_tags.resize(siz);
            for (size_t ind=0; ind<siz; ++ind) {
                m_frame_tags[ind] = o.frame_tags(ind);
            }
        }
        {
            size_t siz = o.trace_tags_size();
            m_trace_tags.resize(siz);
            for (size_t ind=0; ind<siz; ++ind) {
                m_trace_tags[ind] = o.trace_tags(ind);
            }
        }
        pbiface_set(m_, o);
        pbiface_set(m_, o);
        
    }
    virtual ~Frame() {
    }

    
    int32_t ident() const {
        return m_ident;
    }
    float time() const {
        return m_time;
    }
    float tick() const {
        return m_tick;
    }
    std::vector<Trace> traces() const {
        return m_traces;
    }
    std::vector<std::string> frame_tags() const {
        return m_frame_tags;
    }
    std::vector<std::string> trace_tags() const {
        return m_trace_tags;
    }
    std::vector<TraceInfo> trace_info() const {
        return m_trace_info;
    }
    std::vector<TaggedChannelMasks> tcm() const {
        return m_tcm;
    }

    
    const WireCell::IFrame::trace_list_t& tagged_traces(const tag_t& tag) const;
    
    const WireCell::IFrame::trace_summary_t& trace_summary(const tag_t& tag) const;
    

  private:
    
    int32_t m_ident;
    
    float m_time;
    
    float m_tick;
    
    std::vector<Trace> m_traces;
    
    std::vector<std::string> m_frame_tags;
    
    std::vector<std::string> m_trace_tags;
    
    std::vector<TraceInfo> m_trace_info;
    
    std::vector<TaggedChannelMasks> m_tcm;
    
};




// Frame: fill PB object from iface pointer 
void WireCell::PB::fillpb(
    wct.pb::Frame& pbobj,
    const WireCell::IFrame::pointer& ptr)
{
    {   // ident copy as scalar
        pbobj.set_ident(ptr->ident());
    }
    {   // time copy as scalar
        pbobj.set_time(ptr->time());
    }
    {   // tick copy as scalar
        pbobj.set_tick(ptr->tick());
    }
    {   // traces hand-wired copy
        pbiface_fill_traces(pbobj, ptr);
    }
    {   // frame_tags copy as array
        auto vec = ptr->frame_tags();
        size_t siz = vec->size();
        RepeatedField<std::string> pbattr;
        pbattr.Reserve(size);
        for (size_t ind=0; ind<size; ++ind) {
            pbattr[ind] = vec[ind];
        }
        pbobj.mutable_frame_tags()->Swap(&pbattr);        
    }
    {   // trace_tags copy as array
        auto vec = ptr->trace_tags();
        size_t siz = vec->size();
        RepeatedField<std::string> pbattr;
        pbattr.Reserve(size);
        for (size_t ind=0; ind<size; ++ind) {
            pbattr[ind] = vec[ind];
        }
        pbobj.mutable_trace_tags()->Swap(&pbattr);        
    }
    {   // trace_info hand-wired copy
        pbiface_fill_trace_info(pbobj, ptr);
    }
    {   // tcm hand-wired copy
        pbiface_fill_tcm(pbobj, ptr);
    }
    
}

