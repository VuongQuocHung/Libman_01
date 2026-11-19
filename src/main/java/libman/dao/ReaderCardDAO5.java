package libman.dao;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Reader5;
import libman.model.ReaderCard5;

public class ReaderCardDAO5 extends DAO5 {

    public ReaderCardDAO5() throws SQLException {
        super();
    }

    /**
     * Tìm thẻ theo mã thẻ (quét thẻ), kèm thông tin độc giả; null nếu không có.
     * Một truy vấn lấy cả thẻ lẫn độc giả: tblReaderCard5 -> tblReader5 -> tblMember5.
     * Cột c.id đặt bí danh cardId để không trùng với cột m.id (id của độc giả).
     */
    public ReaderCard5 getCardByCode(String cardCode) throws SQLException {
        String sql = "SELECT c.id AS cardId, c.cardCode, c.registrationDate, c.expiryDate, "
                + "c.cardStatus, c.photo, "
                + "m.id, m.username, m.fullName, m.birthDate, m.email, m.phone, m.address, m.is_active, "
                + "r.readerCode "
                + "FROM tblReaderCard5 c "
                + "JOIN tblReader5 r ON r.id = c.readerId "
                + "JOIN tblMember5 m ON m.id = r.id "
                + "WHERE c.cardCode = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, cardCode);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                // Đóng gói thẻ trước
                ReaderCard5 card = new ReaderCard5();
                card.setId(rs.getInt("cardId"));
                card.setCardCode(rs.getString("cardCode"));
                card.setRegistrationDate(rs.getDate("registrationDate"));
                card.setExpiryDate(rs.getDate("expiryDate"));
                card.setCardStatus(rs.getString("cardStatus"));
                card.setPhoto(rs.getString("photo"));

                // Sau đó đóng gói độc giả rồi gắn vào thẻ
                Reader5 reader = new Reader5();
                reader.setId(rs.getInt("id"));
                reader.setUsername(rs.getString("username"));
                reader.setFullName(rs.getString("fullName"));
                reader.setBirthDate(rs.getDate("birthDate"));
                reader.setEmail(rs.getString("email"));
                reader.setPhone(rs.getString("phone"));
                reader.setAddress(rs.getString("address"));
                reader.setActive(rs.getBoolean("is_active"));
                reader.setReaderCode(rs.getString("readerCode"));

                card.setReader(reader);
                return card;
            }
        }
    }
}
