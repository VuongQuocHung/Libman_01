package libman.model;

/** Chi tiết phiếu mượn: một bản tài liệu trong một phiếu mượn. */
public class BorrowingDetail5 {
    private Integer id;
    private String conditionOnBorrowing;
    private DocumentCopy5 documentCopy;

    public BorrowingDetail5() {
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getConditionOnBorrowing() {
        return conditionOnBorrowing;
    }

    public void setConditionOnBorrowing(String conditionOnBorrowing) {
        this.conditionOnBorrowing = conditionOnBorrowing;
    }

    public DocumentCopy5 getDocumentCopy() {
        return documentCopy;
    }

    public void setDocumentCopy(DocumentCopy5 documentCopy) {
        this.documentCopy = documentCopy;
    }
}
