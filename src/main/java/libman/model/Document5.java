package libman.model;

/** Đầu tài liệu (sách, giáo trình, tạp chí...). */
public class Document5 {
    private Integer id;
    private String documentCode;
    private String title;
    private String documentType;
    private String author;
    private String publisher;
    private Integer year;
    private String description;
    private String language;
    private Integer pageCount;
    private String documentStatus;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getDocumentCode() { return documentCode; }
    public void setDocumentCode(String documentCode) { this.documentCode = documentCode; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDocumentType() { return documentType; }
    public void setDocumentType(String documentType) { this.documentType = documentType; }
    public String getAuthor() { return author; }
    public void setAuthor(String author) { this.author = author; }
    public String getPublisher() { return publisher; }
    public void setPublisher(String publisher) { this.publisher = publisher; }
    public Integer getYear() { return year; }
    public void setYear(Integer year) { this.year = year; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    public Integer getPageCount() { return pageCount; }
    public void setPageCount(Integer pageCount) { this.pageCount = pageCount; }
    public String getDocumentStatus() { return documentStatus; }
    public void setDocumentStatus(String documentStatus) { this.documentStatus = documentStatus; }

    public boolean isInUse() { return Status5.DOC_ACTIVE.equals(documentStatus); }
}
