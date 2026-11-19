package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Reader5;
import libman.model.ReaderCard5;
import libman.util.DBUtil;

public class ReaderCardDAO5 {

    /**
     * Tìm thẻ theo mã thẻ (quét thẻ), kèm đầy đủ thông tin độc giả; null nếu không có.
     *
     * Một truy vấn lấy cả thẻ lẫn độc giả của thẻ: tblReaderCard5 -> tblReader5 -> tblMember5.
     * Cột c.id đặt bí danh cardId để không trùng với cột m.id (id của thành viên/độc giả).
     */
    public ReaderCard5 getCardByCode(String cardCode) throws SQLException {
        String sql = "SELECT c.id AS cardId, c.cardCode, c.registrationDate, "
                + "c.expiryDate, c.cardStatus, c.photo, "
                + MemberMapper.MEMBER_COLUMNS + ", r.readerCode "
                + "FROM tblReaderCard5 c "
                + "JOIN tblReader5 r ON r.id = c.readerId "
                + "JOIN tblMember5 m ON m.id = r.id "
                + "WHERE c.cardCode = ?";

        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
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
                MemberMapper.fill(reader, rs);
                reader.setReaderCode(rs.getString("readerCode"));
                card.setReader(reader);
                return card;
            }
        }
    }
}
