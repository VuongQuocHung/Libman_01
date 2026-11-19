package libman.model;

import java.sql.Date;

/** Thẻ độc giả. */
public class ReaderCard5 {
    private Integer id;
    private String cardCode;
    private Date registrationDate;
    private Date expiryDate;
    private String cardStatus;
    private String photo;
    private Reader5 reader;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getCardCode() {
        return cardCode;
    }

    public void setCardCode(String cardCode) {
        this.cardCode = cardCode;
    }

    public Date getRegistrationDate() {
        return registrationDate;
    }

    public void setRegistrationDate(Date registrationDate) {
        this.registrationDate = registrationDate;
    }

    public Date getExpiryDate() {
        return expiryDate;
    }

    public void setExpiryDate(Date expiryDate) {
        this.expiryDate = expiryDate;
    }

    public String getCardStatus() {
        return cardStatus;
    }

    public void setCardStatus(String cardStatus) {
        this.cardStatus = cardStatus;
    }

    public String getPhoto() {
        return photo;
    }

    public void setPhoto(String photo) {
        this.photo = photo;
    }

    public Reader5 getReader() {
        return reader;
    }

    public void setReader(Reader5 reader) {
        this.reader = reader;
    }

    /** Thẻ đã hết hạn tính đến ngày today. */
    public boolean isExpiredOn(Date today) {
        return expiryDate != null && expiryDate.before(today);
    }

    /** Thẻ dùng được: đang hoạt động và chưa hết hạn. */
    public boolean isValidOn(Date today) {
        return Status5.ACTIVE.equals(cardStatus) && !isExpiredOn(today);
    }
}
