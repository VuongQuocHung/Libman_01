package libman.model;

/** Bản tài liệu: một bản vật lí cụ thể của một đầu tài liệu. */
public class DocumentCopy5 {
    private Integer id;
    private String copyCode;
    private String location;
    private String copyCondition;
    private String usageStatus;
    private Document5 document;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getCopyCode() {
        return copyCode;
    }

    public void setCopyCode(String copyCode) {
        this.copyCode = copyCode;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getCopyCondition() {
        return copyCondition;
    }

    public void setCopyCondition(String copyCondition) {
        this.copyCondition = copyCondition;
    }

    public String getUsageStatus() {
        return usageStatus;
    }

    public void setUsageStatus(String usageStatus) {
        this.usageStatus = usageStatus;
    }

    public Document5 getDocument() {
        return document;
    }

    public void setDocument(Document5 document) {
        this.document = document;
    }

    /** Bản có thể cho mượn: trạng thái "Sẵn có" và không hư hỏng. */
    public boolean isLendable() {
        return Status5.COPY_AVAILABLE.equals(usageStatus) && !Status5.COND_DAMAGED.equals(copyCondition);
    }
}
