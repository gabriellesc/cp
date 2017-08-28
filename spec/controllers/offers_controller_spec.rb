require 'rails_helper'

RSpec.describe OffersController, type: :controller do
  let(:offer) do
    Offer.create!(
        position_id: 6,
        applicant_id: 1,
        hours: 60,
        link: "mangled-link",
    )
  end
  let(:sent_offer) do
    Offer.create!(
        position_id: 6,
        applicant_id: 2,
        hours: 60,
        status: "Pending",
        link: "mangled-link",
    )
  end
  let(:accepted_offer) do
    Offer.create!(
        position_id: 6,
        applicant_id: 3,
        hours: 60,
        status: "Accepted",
        link: "mangled-link",
    )
  end

  describe "GET /offers/" do
    context "when expected" do
      it "lists all offers" do
        get :index
        expect(response.status).to eq(200)
        expect(response.body).not_to be_empty
      end
    end

    context "when /offers/{id} exists" do
      it "lists offers with {id}" do
        get :show, params: {id: offer[:id]}
        expect(response.status).to eq(200)
        expect(response.body).not_to be_empty
      end
    end

    context "when {id} is a non-existent id" do
      it "throws status 404" do
        get :show, params: {id: "poop"}
        expect(response.status).to eq(404)
      end
    end

  end

  describe "POST /offers/" do
    context "send-contracts" do
      before(:each) do
        expect(offer[:status]).to eq("Unsent")
      end
      it "returns a message of whether the contract has been sent" do
        post :send_contracts, params: {offers: [offer[:id]]}
        offer.reload
        expect(response.status).to eq(200)
        expect(response.body).to eq({
          message: "You've successfully sent out all the contracts."
        }.to_json)
        expect(offer[:status]).to eq("Pending")
        post :send_contracts, params: {offers: [offer[:id]]}
        offer.reload
        expect(response.status).to eq(404)
        expect(offer[:status]).to eq("Pending")
        expect(response.body).to eq({
          message: "Exceptions:\nYou've already sent out a contract to #{offer.format[:applicant][:email]}."
        }.to_json)
      end
    end

    context "nag" do
      before(:each) do
        expect(offer[:nag_count]).to eq(0)
      end
      it "return a message of the number of time a applicant has been nagged at" do
        post :batch_email_nags, params: {contracts: [offer[:id]]}
        offer.reload
        expect(response.status).to eq(200)
        expect(offer[:nag_count]).to eq(1)
        res = ({ message: "You've sent the nag emails."}).to_json
        expect(response.body).to eq(res)
      end
    end

    context ":offer_id/decision/:status" do
      context "when offer_id doesn't exists" do
        it "returns a status 404" do
          post :set_status, params: {offer_id: "poop", status: "accept"}
          expect(response.status).to eq(404)
        end
      end
      context "when offer_id does exists" do
        context "when status is pending" do
          context "code = accept" do
            it "updates the offer status to Accepted" do
              post :set_status, params: {offer_id: sent_offer[:id], status: "accept"}
              expect(response.status).to eq(200)
              body = {success: true, status: "accepted", message: "You've just accepted this offer."}
              expect(response.body).to eq(body.to_json)
            end
          end

          context "code = reject" do
            it "updates the offer status to Rejected" do
              post :set_status, params: {offer_id: sent_offer[:id], status: "reject"}
              expect(response.status).to eq(200)
              body = {success: true, status: "rejected", message: "You've just rejected this offer."}
              expect(response.body).to eq(body.to_json)
            end
          end

          context "code = withdraw" do
            it "updates the offer status to Withdrawn" do
              post :set_status, params: {offer_id: sent_offer[:id], status: "withdraw"}
              expect(response.status).to eq(200)
              body = {success: true, status: "withdrawn", message: "You've just withdrawn this offer."}
              expect(response.body).to eq(body.to_json)
            end
          end
        end

        context "when status is Unsent" do
          context "code = accept" do
            it "returns a status 404 with a message" do
              post :set_status, params: {offer_id: offer[:id], status: "accept"}
              expect(response.status).to eq(404)
              body = {success: false, message: "You cannot accept an unsent offer."}
              expect(response.body).to eq(body.to_json)
            end
          end

          context "code = reject" do
            it "updates the offer status to Rejected" do
              post :set_status, params: {offer_id: offer[:id], status: "reject"}
              expect(response.status).to eq(404)
              body = {success: false, message: "You cannot reject an unsent offer."}
              expect(response.body).to eq(body.to_json)
            end
          end

          context "code = withdraw" do
            it "updates the offer status to Withdrawn" do
              post :set_status, params: {offer_id: offer[:id], status: "withdraw"}
              expect(response.status).to eq(404)
              body = {success: false, message: "You cannot withdraw an unsent offer."}
              expect(response.body).to eq(body.to_json)
            end
          end
        end

        context "when status decided" do
          context "code = accept" do
            it "returns a status 404 with a message" do
              post :set_status, params: {offer_id: accepted_offer[:id], status: "accept"}
              expect(response.status).to eq(404)
              body = {success: false, message: "You cannot reject this offer. This offer has already been accepted."}
              expect(response.body).to eq(body.to_json)
            end
          end

          context "code = reject" do
            it "updates the offer status to Rejected" do
              post :set_status, params: {offer_id: accepted_offer[:id], status: "reject"}
              expect(response.status).to eq(404)
              body = {success: false, message: "You cannot reject this offer. This offer has already been accepted."}
              expect(response.body).to eq(body.to_json)
            end
          end

          context "code = withdraw" do
            it "updates the offer status to Withdrawn" do
              post :set_status, params: {offer_id: accepted_offer[:id], status: "withdraw"}
              expect(response.status).to eq(404)
              body = {success: false, message: "You cannot reject this offer. This offer has already been accepted."}
              expect(response.body).to eq(body.to_json)
            end
          end
        end
      end

    end

    context "print with update" do
      it "sends a PDF blob" do
        post :combine_contracts_print, params: {contracts: [offer[:id]], update: true}
        expect(response.status).to eq(200)
        expect(response.content_type).to eq("application/pdf")
        expect(response.header["Content-Disposition"]).to eq(
          "inline; filename=\"contracts.pdf\"")
        offer.reload
        expect(offer[:hr_status]).to eq("Printed")
      end
    end

    context "print without update" do
      it "sends a PDF blob" do
        post :combine_contracts_print, params: {contracts: [offer[:id]]}
        expect(response.status).to eq(200)
        expect(response.content_type).to eq("application/pdf")
        expect(response.header["Content-Disposition"]).to eq(
          "inline; filename=\"contracts.pdf\"")
        offer.reload
        expect(offer[:hr_status]).to eq(nil)
      end
    end


  end

  describe "PATCH /offers/:id" do
    before(:each) do
      expect(offer[:hr_status]).to eq(nil)
      expect(offer[:ddah_status]).to eq(nil)
    end
    it "returns status 204 and updates offer" do
      patch :update, params: {id: offer[:id], hr_status: "printed", ddah_status: "accepted"}
      offer.reload
      expect(response.status).to eq(204)
      expect(offer[:hr_status]).to eq("printed")
      expect(offer[:ddah_status]).to eq("accepted")
    end
  end

  describe "PATCH /offers/batch-update" do
    before(:each) do
      expect(offer[:hr_status]).to eq(nil)
      expect(offer[:ddah_status]).to eq(nil)
    end
    it "returns status 204 and updates offer" do
      patch :update, params: {id: "batch-update", offers: [offer[:id]], hr_status: "printed", ddah_status: "accepted"}
      offer.reload
      expect(response.status).to eq(204)
      expect(offer[:hr_status]).to eq("printed")
      expect(offer[:ddah_status]).to eq("accepted")
    end
    it "returns status 404 when there is no offers" do
      patch :update, params: {id: "batch-update", hr_status: "printed", ddah_status: "accepted"}
      offer.reload
      expect(response.status).to eq(404)
    end
  end

  describe "GET pb/:mangled/pdf" do
    context "when :mangled is valid" do
      it "returns status 200 a pdf" do
        get :get_contract_mangled, params: {mangled: offer[:link]}
        expect(response.status).to eq(200)
        expect(response.content_type).to eq("application/pdf")
        expect(response.header["Content-Disposition"]).to eq(
          "inline; filename=\"contract.pdf\"")
      end
    end

    context "when :mangled is invalid" do
      it "returns status 404 and an error message" do
        get :get_contract_mangled, params: {mangled: "poops"}
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST pb/:mangled/:status" do
    context "when offer_id does exists" do
      context "when status is pending" do
        context "code = accept" do
          it "updates the offer status to Accepted" do
            post :set_status_mangled, params: {mangled: sent_offer[:link], status: "accept"}
            expect(response.status).to eq(200)
            body = {success: true, status: "accepted", message: "You've just accepted this offer."}
            expect(response.body).to eq(body.to_json)
          end
        end

        context "code = reject" do
          it "updates the offer status to Rejected" do
            post :set_status_mangled, params: {mangled: sent_offer[:link], status: "reject"}
            expect(response.status).to eq(200)
            body = {success: true, status: "rejected", message: "You've just rejected this offer."}
            expect(response.body).to eq(body.to_json)
          end
        end

        context "code = withdraw" do
          it "updates the offer status to Withdrawn" do
            post :set_status_mangled, params: {mangled: sent_offer[:link], status: "withdraw"}
            expect(response.status).to eq(404)
            body = {success: false, message: "Error: no permission to set such status"}
            expect(response.body).to eq(body.to_json)
          end
        end
      end

      context "when status is Unsent" do
        context "code = accept" do
          it "returns a status 404 with a message" do
            post :set_status_mangled, params: {mangled: offer[:link], status: "accept"}
            expect(response.status).to eq(404)
            body = {success: false, message: "You cannot accept an unsent offer."}
            expect(response.body).to eq(body.to_json)
          end
        end

        context "code = reject" do
          it "updates the offer status to Rejected" do
            post :set_status_mangled, params: {mangled: offer[:link], status: "reject"}
            expect(response.status).to eq(404)
            body = {success: false, message: "You cannot reject an unsent offer."}
            expect(response.body).to eq(body.to_json)
          end
        end

        context "code = withdraw" do
          it "updates the offer status to Withdrawn" do
            post :set_status_mangled, params: {mangled: offer[:link], status: "withdraw"}
            expect(response.status).to eq(404)
            body = {success: false, message: "Error: no permission to set such status"}
            expect(response.body).to eq(body.to_json)
          end
        end
      end

      context "when status decided" do
        context "code = accept" do
          it "returns a status 404 with a message" do
            post :set_status_mangled, params: {mangled: accepted_offer[:link], status: "accept"}
            expect(response.status).to eq(404)
            body = {success: false, message: "You cannot reject this offer. This offer has already been accepted."}
            expect(response.body).to eq(body.to_json)
          end
        end

        context "code = reject" do
          it "updates the offer status to Rejected" do
            post :set_status_mangled, params: {mangled: accepted_offer[:link], status: "reject"}
            expect(response.status).to eq(404)
            body = {success: false, message: "You cannot reject this offer. This offer has already been accepted."}
            expect(response.body).to eq(body.to_json)
          end
        end

        context "code = withdraw" do
          it "updates the offer status to Withdrawn" do
            post :set_status_mangled, params: {mangled: accepted_offer[:link], status: "withdraw"}
            expect(response.status).to eq(404)
            body = {success: false, message: "Error: no permission to set such status"}
            expect(response.body).to eq(body.to_json)
          end
        end
      end
    end

  end

end
